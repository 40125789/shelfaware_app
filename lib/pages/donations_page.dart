import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/components/donation_details_dialogue.dart';
import 'package:shelfaware_app/components/donation_list_widget.dart';
import 'package:shelfaware_app/components/donation_search_bar.dart';
import 'package:shelfaware_app/components/filter_dialogue_widget.dart';
import 'package:shelfaware_app/services/location_service.dart';
import 'package:shelfaware_app/services/map_service.dart';
import 'package:shelfaware_app/services/places_service.dart';
import 'package:shelfaware_app/models/place.dart';
import 'package:shelfaware_app/models/place_details.dart';
import 'package:shelfaware_app/models/donation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shelfaware_app/utils/location_permission_util.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart' as latlong2;



class DonationsPage extends StatefulWidget {
  @override
  _DonationsScreenState createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsPage> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  final PlacesService _placesService = PlacesService();

  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  late GoogleMapController _googleMapController;
  late TabController _tabController;
  bool _isLoading = true;
  String? _userId;
  bool _filterExpiringSoon = false;
  bool _filterNewlyAdded = false;
  double _filterDistance = 0.0;
  List<DonationLocation> _allDonations = [];
  List<DonationLocation> _filteredDonations = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _requestLocationPermission();
    _getUserId();
  }

  Future<void> _getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      await _getUserLocationFromFirestore(user.uid);
    } else {
      print("User is not logged in");
    }
  }

  Future<void> _getUserLocationFromFirestore(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        var userLocationData = userDoc.data() as Map<String, dynamic>;
        if (userLocationData['location'] != null) {
          GeoPoint location = userLocationData['location'];
          setState(() {
            _currentLocation = LatLng(location.latitude, location.longitude);
          });
          _loadMap();
        }
      }
    } catch (e) {
      print("Error fetching user location from Firestore: $e");
    }
  }

  Future<void> _requestLocationPermission() async {
    bool granted = await LocationPermissionUtil.requestLocationPermission(context);
    if (granted) {
      _loadMap();
    }
  }

  Future<void> _loadMap() async {
    try {
      if (_currentLocation == null) {
        await _getUserLocationFromFirestore(_userId!);
      }
      if (_currentLocation == null) {
        final position = await _locationService.getCurrentLocation();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      }
      final donationLocations = await fetchDonationLocations();
      _allDonations = donationLocations;
      _filteredDonations = List.from(_allDonations);
      await _updateMarkers(_filteredDonations);

      final foodBanks = await _placesService.getNearbyFoodBanks(_currentLocation!);
      Set<Marker> foodBankMarkers = await Future.wait(foodBanks.map((place) async {
        final details = await _placesService.getPlaceDetails(place.placeId);
        String snippetText = details != null && details.openingHours != null && details.openingHours!.isNotEmpty
            ? details.openingHours!.first
            : "No opening hours available";
        return Marker(
          markerId: MarkerId(place.name),
          position: place.location,
          infoWindow: InfoWindow(
            title: place.name,
            snippet: snippetText,
            onTap: () => _showPlaceDetails(context, place, details),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );
      }).toList()).then((markers) => markers.toSet());
      if (mounted) {
        setState(() {
          _markers = {
            ..._markers,
            ...foodBankMarkers,
          };
        });
      }
    } catch (e) {
      print("Error loading map: $e");
    }
  }

  Future<void> _updateMarkers(List<DonationLocation> donations) async {
    try {
      Set<Marker> donationMarkers = await _mapService.getMarkers(
        _currentLocation!,
        donations.where((donation) => donation.status != 'Picked Up').toList(),
        [],
        _userId!,
        (donation) {
          _showDonationDetails(context, donation);
        },
      );
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value.startsWith('donation_'));
        _markers.addAll(donationMarkers);
      });
    } catch (e) {
      print("Error updating markers: $e");
    }
  }

  Future<List<DonationLocation>> fetchDonationLocations() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('donations').get();
      final donations = snapshot.docs.map((doc) {
        var donation = DonationLocation.fromFirestore(doc.data() as Map<String, dynamic>);
        if (donation.id != _userId) {
          return donation;
        }
        return null;
      }).whereType<DonationLocation>().toList();

      const double defaultDistance = 10.0;
      donations.removeWhere((donation) {
        final distance = donation.filterDistance(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          donation.location.latitude,
          donation.location.longitude,
        );
        return distance > defaultDistance;
      });

      if (_filterExpiringSoon) {
        donations.removeWhere((donation) {
          DateTime expiryDate = DateTime.parse(donation.expiryDate);
          return !expiryDate.isBefore(DateTime.now().add(Duration(days: 7)));
        });
      }
      if (_filterNewlyAdded) {
        donations.sort((a, b) => b.addedOn.compareTo(a.addedOn));
      }
      if (_filterDistance > 0) {
        donations.removeWhere((donation) {
          final distance = donation.filterDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            donation.location.latitude,
            donation.location.longitude,
          );
          return distance > _filterDistance;
        });
      }
      setState(() {
        _isLoading = false;
      });
      return donations;
    } catch (e) {
      print('Error fetching donation locations: $e');
      return [];
    }
  }

  void _showPlaceDetails(BuildContext context, Place place, PlaceDetails? details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Address: ${place.address}"),
            SizedBox(height: 8.0),
            Text("Opening Hours: ${details?.openingHours?.join(', ') ?? 'No opening hours available'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showDonationDetails(BuildContext context, DonationLocation donation) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(donation.location.latitude, donation.location.longitude);
    String address = '';
    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks[0];
      address = '${placemark.thoroughfare}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';
    }
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return DonationDetailsDialog(
          donorName: donation.donorName,
          imageUrl: donation.imageUrl,
          status: donation.status,
          donationLatitude: donation.location.latitude,
          donationLongitude: donation.location.longitude,
          userLatitude: _currentLocation?.latitude ?? 0.0,
          userLongitude: _currentLocation?.longitude ?? 0.0,
          productName: donation.itemName,
          expiryDate: donation.expiryDate,
          donorEmail: donation.donorEmail,
          donatorId: donation.donorId,
          chatId: '',
          donorImageUrl: donation.imageUrl,
          donationTime: DateTime.parse(donation.addedOn),
          donationId: donation.donationId,
          receiverEmail: donation.donorEmail,
          pickupTimes: donation.pickupTimes,
          pickupInstructions: donation.pickupInstructions,
        );
      },
    );
  }

  void _showFilterDialog() {
    if (_tabController.index == 0) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: FilterDialog(
                filterExpiringSoon: _filterExpiringSoon,
                filterNewlyAdded: _filterNewlyAdded,
                filterDistance: _filterDistance,
                onExpiringSoonChanged: (bool value) {
                  setState(() => _filterExpiringSoon = value);
                },
                onNewlyAddedChanged: (bool value) {
                  setState(() => _filterNewlyAdded = value);
                },
                onDistanceChanged: (double? value) {
                  setState(() => _filterDistance = value ?? 0.0);
                },
                onApply: () async {
                  Navigator.of(context).pop();
                  setState(() {
                    _isLoading = true;
                  });
                  _allDonations = await fetchDonationLocations();
                  _applySearchFilter(_searchQuery);
                  await _updateMarkers(_filteredDonations);
                },
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          barrierDismissible: true,
          barrierColor: Colors.black54,
        ),
      );
    }
  }

  void _applySearchFilter(String query) {
    setState(() {
      _searchQuery = query;
      if (_searchQuery.isEmpty) {
        _filteredDonations = List.from(_allDonations);
      } else {
        _filteredDonations = _allDonations.where((donation) {
          return donation.itemName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _launchFoodBankMap() async {
    if (_currentLocation != null) {
      final latitude = _currentLocation!.latitude;
      final longitude = _currentLocation!.longitude;
      final googleMapsUrl = 'https://www.google.com/maps/search/food+bank/@$latitude,$longitude,12z';
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        throw 'Could not launch $googleMapsUrl';
      }
    } else {
      print("Current location not available");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Donations List'),
              Tab(text: 'Donations Map'),
            ],
          ),
          if (_tabController.index == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Row(
                      children: [
                        Icon(Icons.filter_alt_rounded),
                        SizedBox(width: 4),
                        Text('Filter', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filter Donations',
                  ),
                ],
              ),
            ),
          if (_tabController.index == 1)
            SearchBarWidget(
              searchController: _searchController,
              onChanged: (query) {
                _applySearchFilter(query);
                _updateMarkers(_filteredDonations);
              },
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: [
                      DonationListView(
                        filterExpiringSoon: _filterExpiringSoon,
                        filterNewlyAdded: _filterNewlyAdded,
                        filterDistance: _filterDistance,
                        currentLocation: _currentLocation != null
                            ? latlong2.LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
                            : null,
                      ),
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation ?? LatLng(0, 0),
                          zoom: 14,
                        ),
                        markers: _markers,
                        onMapCreated: (GoogleMapController controller) {
                          _googleMapController = controller;
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomGesturesEnabled: true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: _launchFoodBankMap,
                  child: Icon(Icons.map),
                  tooltip: 'Find Nearby Food Banks',
                ),
              ),
            )
          : null,
    );
  }
}