import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/components/donation_details_dialogue.dart';
import 'package:shelfaware_app/pages/chat_page.dart';

class DonationMapScreen extends StatefulWidget {
  final double donationLatitude;
  final double donationLongitude;
  final double userLatitude;
  final double userLongitude;
  final String productName;
  final String expiryDate;
  final String status;
  final String donorName;
  final String chatId; // Unique chat ID
  final String donorEmail; // Added donor email
  final String donatorId; 
  final String donationId;
  // Added donator ID
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  // Added donor name
  // Added status for the item

  DonationMapScreen({
    required this.donationLatitude,
    required this.donationLongitude,
    required this.userLatitude,
    required this.userLongitude,
    required this.productName,
    required this.expiryDate,
    required this.status,
    required this.donorEmail, // Added donor email
    required this.donatorId, // Added donator ID
    required this.chatId,
    required this.userId,
    required this.donorName,
    required String receiverEmail,
   required this.donationId,
  });

  @override
  _DonationMapScreenState createState() => _DonationMapScreenState();
}

class _DonationMapScreenState extends State<DonationMapScreen> {
  late GoogleMapController mapController;

  // Markers for the donation and user
  late Marker donationMarker;
  late Marker userMarker;

  late String address = '';

  @override
  void initState() {
    super.initState();

    // Donation marker (Blue marker for the donation location)
    donationMarker = Marker(
      markerId: MarkerId('donationLocation'),
      position: LatLng(widget.donationLatitude, widget.donationLongitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Blue marker for donation
      infoWindow: InfoWindow(
        title: widget.productName,
        snippet: 'Expires on: ${widget.expiryDate}\nStatus: ${widget.status}',
      ),
      onTap: _showDonationDetails, // Trigger the modal when tapped
    );

    // User marker (Red marker for user's location)
    userMarker = Marker(
      markerId: MarkerId('userLocation'),
      position: LatLng(widget.userLatitude, widget.userLongitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red marker for user location
      infoWindow: InfoWindow(title: 'Your Location'),
    );

    // Get address for donation location
    _getAddress();
  }

  // Get the address from latitude and longitude
  void _getAddress() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      widget.donationLatitude,
      widget.donationLongitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks[0];
      setState(() {
        address =
            '${placemark.thoroughfare}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';
      });
    }
  }

  // Show donation details when marker is tapped
  void _showDonationDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DonationDetailsDialog(
          itemName: widget.productName,
          formattedExpiryDate: widget.expiryDate,
          donorName: widget.donorName,
          address: address.isEmpty ? 'Loading address...' : address, // Show loading until address is fetched
          onContactDonor: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  donorName: widget.donorName,
                  userId: widget.userId,
                  receiverEmail: widget.donorEmail,
                  receiverId: widget.donatorId,
                  donationId: widget.donationId,
                  donationName: widget.productName, chatId: '',
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng donationLocation = LatLng(widget.donationLatitude, widget.donationLongitude);
    final LatLng userLocation = LatLng(widget.userLatitude, widget.userLongitude);

    // Calculate the distance
    double distanceInMeters = Geolocator.distanceBetween(
      widget.userLatitude,
      widget.userLongitude,
      widget.donationLatitude,
      widget.donationLongitude,
    );
    double distanceInKm = distanceInMeters / 1000; // Convert to km

    return Scaffold(
      appBar: AppBar(title: Text('Donation Location'), backgroundColor: Colors.green),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: donationLocation,
          zoom: 14.0, // Adjust zoom to make sure both markers are visible
        ),
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: {
          donationMarker,
          userMarker, // Add user marker here
        },
        circles: {
          Circle(
            circleId: CircleId('radius'),
            center: donationLocation,
            radius: 500, // Define the radius in meters, e.g., 500 meters
            strokeColor: Colors.blue.withOpacity(0.5),
            strokeWidth: 2,
            fillColor: Colors.blue.withOpacity(0.1),
          ),
        },
      ),
    );
  }
}
