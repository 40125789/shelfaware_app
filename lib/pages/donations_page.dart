import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/components/donation_details_dialogue.dart';
import 'package:shelfaware_app/components/donation_list_widget.dart';
import 'package:shelfaware_app/components/filter_dialogue_widget.dart';
import 'package:shelfaware_app/components/user_donation_map_widget.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/pages/donation_detail_page.dart';
import 'package:shelfaware_app/services/location_service.dart';
import 'package:shelfaware_app/services/map_service.dart';
import 'package:shelfaware_app/services/places_service.dart';
import 'package:shelfaware_app/models/place.dart';
import 'package:shelfaware_app/models/place_details.dart';
import 'package:shelfaware_app/models/donation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shelfaware_app/services/donation_filter_logic.dart';

class DonationsPage extends StatefulWidget {
  @override
  _DonationsScreenState createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsPage>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  final PlacesService _placesService = PlacesService();

  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  late GoogleMapController _googleMapController;
  late TabController _tabController;
  bool _isLoading = true;
  String? _userId; // To store the logged-in user's ID
  bool _filterExpiringSoon = false; // Define the variable
  bool _filterNewlyAdded = false; // Define the variable
  double _filterDistance = 0.0; // Define the variable
  List<DonationLocation> _allDonations = []; // Define the variable

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      print('Tab Index: ${_tabController.index}');
      setState(() {}); // Trigger rebuild when tab changes
    });
    _requestLocationPermission();
    _getUserId();
  }

  // Get logged-in user ID from FirebaseAuth
  Future<void> _getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _userId = user.uid; // Set the user ID
      });
    } else {
      print("User is not logged in");
      // Handle user not logged in (e.g., navigate to login screen)
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      _loadMap();
    } else {
      _showPermissionAlert();
    }
  }

  void _showPermissionAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Location Permission Required"),
        content: Text(
            "This app needs location access to show nearby donation points. Please enable location permissions in settings."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text("Go to Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMap() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Fetch donation locations
      final donationLocations = await fetchDonationLocations();

      // Create donation markers (excluding the logged-in user's donations)
      Set<Marker> donationMarkers = _mapService.getMarkers(
        _currentLocation!,
        donationLocations,
        [], // This can be used for predefined points if needed
        _userId!,
        (donation) {
          // Handle tap on a donation marker
          print('Tapped on donation: ${donation.itemName}');
          _showDonationDetails(context, donation);
        }, // Logged-in user's ID to filter out their donations
      );

      // Fetch nearby food banks and create food bank markers
      final foodBanks =
          await _placesService.getNearbyFoodBanks(_currentLocation!);
      Set<Marker> foodBankMarkers =
          await Future.wait(foodBanks.map((place) async {
        final details = await _placesService.getPlaceDetails(place.placeId);

        String snippetText;
        if (details != null &&
            details.openingHours != null &&
            details.openingHours!.isNotEmpty) {
          snippetText = details.openingHours!.first;
        } else {
          snippetText = "No opening hours available";
        }

        return Marker(
          markerId: MarkerId(place.name),
          position: place.location,
          infoWindow: InfoWindow(
            title: place.name,
            snippet: snippetText,
            onTap: () => _showPlaceDetails(context, place, details),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen), // Green for donations
        );
      }).toList())
              .then((markers) => markers.toSet());

      // Combine all markers including the user's location
      if (mounted) {
        setState(() {
          _markers = {
            ...donationMarkers,
            ...foodBankMarkers,
            Marker(
              markerId: MarkerId('user_location'),
              position: _currentLocation!,
              infoWindow: InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed), // Red for user location
            ),
          };
        });
      }
    } catch (e) {
      print("Error loading map: $e");
    }
  }

  // Launch Google Maps to show food banks near the user's location
  Future<void> _launchFoodBankMap() async {
    if (_currentLocation != null) {
      final latitude = _currentLocation!.latitude;
      final longitude = _currentLocation!.longitude;
      final googleMapsUrl =
          'https://www.google.com/maps/search/food+bank/@$latitude,$longitude,12z'; // Search query for food banks

      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        throw 'Could not launch $googleMapsUrl';
      }
    } else {
      print("Current location not available");
    }
  }

  // Show place details on tapping the marker
  void _showPlaceDetails(
      BuildContext context, Place place, PlaceDetails? details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Address: ${place.address}"),
            SizedBox(height: 8.0),
            Text(
                "Opening Hours: ${details?.openingHours?.join(', ') ?? 'No opening hours available'}"),
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

  void _showDonationDetails(
      BuildContext context, DonationLocation donation) async {
    // Format the expiry date
    DateTime expiryDate = DateTime.parse(
        donation.expiryDate); // Assuming donation.expiryDate is in ISO format
    String formattedExpiryDate = DateFormat('dd/MM/yy').format(expiryDate);

    // Get the address from latitude and longitude
    List<Placemark> placemarks = await placemarkFromCoordinates(
      donation.location.latitude,
      donation.location.longitude,
    );

    String address = '';
    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks[0];
      address =
          '${placemark.thoroughfare}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';
    }

    // Show dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DonationDetailsDialog(
          itemName: donation.itemName,
          formattedExpiryDate: formattedExpiryDate,
          donorName: donation.donorName,
          address: address,
          onContactDonor: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  donorName: donation.donorName,
                  userId: donation.userId,
                  receiverEmail: donation.donorEmail,
                  receiverId: donation.donorId,
                  donationId: donation.donationId,
                  donationName: donation.itemName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<DonationLocation>> fetchDonationLocations() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('donations').get();

      // Filter donations to exclude the current user's donations
      final donations = snapshot.docs
          .map((doc) {
            var donation = DonationLocation.fromFirestore(
                doc.data() as Map<String, dynamic>);
            // Ensure you're excluding the donations of the logged-in user
            if (donation.id != _userId) {
              return donation;
            }
            return null; // Exclude the user's own donation
          })
          .whereType<DonationLocation>()
          .toList();

      // Apply filters if they are enabled
      if (_filterExpiringSoon) {
        donations.removeWhere((donation) {
          DateTime expiryDate = DateTime.parse(donation.expiryDate);
          return !expiryDate.isBefore(DateTime.now().add(Duration(days: 7)));
        });
      }
      if (_filterNewlyAdded) {
        donations.sort((a, b) => b.addedOn.compareTo(a.addedOn));
      }
      if (_filterDistance != null && _filterDistance > 0) {
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

      if (mounted) {
        setState(() {
          _isLoading = false;
          _allDonations = donations;
        });
      }
      return donations;
    } catch (e) {
      print('Error fetching donation locations: $e');
      return [];
    }
  }

  // Method to show the filter dialog

  void _showFilterDialog() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
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
                  _isLoading =
                      true; // Show the loading indicator when filter is applied
                });
                // Fetch filtered donations
                await fetchDonationLocations();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Donations'),
            Spacer(), // Push the filter button to the right
            IconButton(
              icon: Row(
                children: [
                  Icon(Icons.filter_alt_rounded), // Filter icon
                  SizedBox(width: 4), // Space between the icon and text
                  Text('Filter', style: TextStyle(fontSize: 16)), // Filter text
                ],
              ),
              onPressed: _showFilterDialog, // Your filter dialog function
              tooltip: 'Filter Donations',
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Donations List'),
            Tab(text: 'Donations Map'),
          ],
        ),
      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                TabBarView(
                  physics:
                      NeverScrollableScrollPhysics(), // Disable swipe gestures
                  controller: _tabController,
                  children: [
                    DonationListView(
                        filterExpiringSoon: _filterExpiringSoon,
                        filterNewlyAdded: _filterNewlyAdded,
                        filterDistance: _filterDistance,
                        currentLocation: _currentLocation),
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
                      onTap: (LatLng latLng) {
                        // You can implement a custom tap behavior here
                      },
                    ),
                  ],
                ),
              ],
            ),

      floatingActionButton:
          _tabController.index == 1 // Check if the selected tab is the map tab
              ? Align(
                  alignment: Alignment.bottomLeft, // Align to the bottom left
                  child: Padding(
                    padding: const EdgeInsets.all(
                        16.0), // Add some padding around the button
                    child: FloatingActionButton(
                      onPressed: _launchFoodBankMap,
                      child: Icon(Icons.map),
                      tooltip: 'Find Nearby Food Banks',
                    ),
                  ),
                )
              : null, // Don't show the button on the donations list page
    );
  }
}

void _updateMarkers(List<DonationLocation> donations) {}
