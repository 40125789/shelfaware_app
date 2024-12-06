import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/components/donation_list_widget.dart';
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
        return AlertDialog(
          title: Text(
            'Product Name: ' + donation.itemName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              // Ensures dialog is scrollable for small screens
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.date_range, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        'Expires on:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 5),
                      Text(
                        formattedExpiryDate,
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.green),
                      SizedBox(width: 10),
                      Text(
                        'Donor:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 5),
                      Text(donation.donorName),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        'Location:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        // Ensures text fits within the dialog
                        child: Text(
                          address,
                          style: TextStyle(color: Colors.blue),
                          overflow: TextOverflow
                              .ellipsis, // Ensures long addresses don't overflow
                          maxLines: 2, // Allows for multi-line text
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          actions: [
            // Contact Donor button to open the Chat Page
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                // Navigate to the chat page (assuming it's implemented and accepts donor ID or name)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      donorName:
                          donation.donorName, // Replace with actual donor name
                      userId: donation.userId,
                      receiverEmail:
                          donation.donorEmail, // Fetch or pass if available
                      receiverId: donation.donorId,
                      donationId: donation.donationId,
                      donationName: donation.itemName,
                      // Provide the chatId if available
                    ), // Pass the required positional argument
                  ),
                );
              },
              child: Text('Contact Donor'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<List<DonationLocation>> fetchDonationLocations() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .get(); // Adjust your query as needed

      // Filter donations to exclude the current user's donations
      return snapshot.docs
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
    } catch (e) {
      print("Error fetching donation locations: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donations'),
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
          : TabBarView(
              physics: NeverScrollableScrollPhysics(), // Disable swipe gestures
              controller: _tabController,
              children: [
                DonationListView(currentLocation: _currentLocation),
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

// Compare this snippet from lib/pages/expiring_items_page.dart:

