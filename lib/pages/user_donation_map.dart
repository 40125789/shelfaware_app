import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void initState() {
    super.initState();

    // Donation marker (Blue marker for the donation location)
    donationMarker = Marker(
      markerId: MarkerId('donationLocation'),
      position: LatLng(widget.donationLatitude, widget.donationLongitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue), // Blue marker for donation
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
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed), // Red marker for user location
      infoWindow: InfoWindow(title: 'Your Location'),
    );
  }

  // Show donation details when marker is tapped
  void _showDonationDetails() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donation Item Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Product: ${widget.productName}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Expires on: ${widget.expiryDate}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Status: ${widget.status}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the modal
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        
                        builder: (context) => ChatPage(
                          donorName: widget
                              .donorName, // Replace with actual donor name
                          userId: widget.userId,
                          receiverEmail: widget.donorEmail,
                          receiverId: widget.donatorId,
                          donationId: widget.donationId,
                          donationName: widget.productName,
                        ),
                      ),
                    );
                  },
                  child: Text('Contact Donor'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng donationLocation =
        LatLng(widget.donationLatitude, widget.donationLongitude);
    final LatLng userLocation =
        LatLng(widget.userLatitude, widget.userLongitude);

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
