import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/components/donation_details_dialogue.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/pages/donation_request_form.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/components/donation_details_dialogue.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/pages/donation_request_form.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/components/donation_details_dialogue.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/pages/donation_request_form.dart';

class DonationMapScreen extends StatefulWidget {
  final double donationLatitude;
  final double donationLongitude;
  final double userLatitude;
  final double userLongitude;
  final String productName;
  final String expiryDate;
  final String status;
  final String donorName;
  final String chatId;
  final String donorEmail;
  final String donatorId;
  final String donationId;
  final String imageUrl;
  final String donorImageUrl; // Donor image URL
  final DateTime donationTime;
  final String pickupTimes;
  final String pickupInstructions;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  DonationMapScreen({
    required this.donationLatitude,
    required this.donationLongitude,
    required this.userLatitude,
    required this.userLongitude,
    required this.productName,
    required this.expiryDate,
    required this.status,
    required this.donorEmail,
    required this.donatorId,
    required this.chatId,
    required this.userId,
    required this.donorName,
    required this.donorImageUrl, // Donor image URL
    required this.donationTime, // Donation time
    required this.imageUrl,
    required this.donationId,
    required receiverEmail,
    required this.pickupTimes,
    required this.pickupInstructions,
  });

  @override
  _DonationMapScreenState createState() => _DonationMapScreenState();
}

class _DonationMapScreenState extends State<DonationMapScreen> {
  late GoogleMapController mapController;
  late Circle donationMarker;
  late Marker userMarker;
  String address = 'Loading address...'; // Initialize with loading text
  bool isMapExpanded = false; // Manage the expanded state of the map
  bool hasRequested = false;
  bool isLoading = true; // Add a loading state
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _getAddress();
    _checkIfAlreadyRequested();
  }

  void _initializeMarkers() {
    donationMarker = Circle(
      circleId: CircleId('donationLocation'),
      center: LatLng(widget.donationLatitude, widget.donationLongitude),
    );

    userMarker = Marker(
      markerId: MarkerId('userLocation'),
      position: LatLng(widget.userLatitude, widget.userLongitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: 'Your Location'),
    );
  }

  void _getAddress() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      widget.donationLatitude,
      widget.donationLongitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks[0];
      setState(() {
        address =
            '${placemark.locality}, ${placemark.country}'; // Simplified address
      });
    }
  }

  void _showDonationDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DonationDetailsDialog(
          itemName: widget.productName,
          formattedExpiryDate: widget.expiryDate,
          donorName: widget.donorName,
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
                  donationName: widget.productName,
                  chatId: '',
                ),
              ),
            );
          },
          imageUrl: widget.imageUrl,
          status: widget.status,
        );
      },
    );
  }

  // Check if the current user has already requested the item
  Future<void> _checkIfAlreadyRequested() async {
    String userId = _auth.currentUser?.uid ?? '';
    try {
      final donationRequestDoc = await FirebaseFirestore.instance
          .collection('donationRequests')
          .where('donationId', isEqualTo: widget.donationId)
          .where('requesterId', isEqualTo: userId)
          .get();

      if (donationRequestDoc.docs.isNotEmpty) {
        setState(() {
          hasRequested = true; // User has already requested the donation
        });
      } else {
        setState(() {
          hasRequested = false; // User has not requested the donation
        });
      }
    } catch (e) {
      print('Error checking donation request: $e');
      // Handle errors appropriately, maybe show a message to the user
    } finally {
      setState(() {
        isLoading = false; // Set loading to false after the check
      });
    }
  }

  String _getTimeRemaining() {
    DateTime? expiryDate;

    try {
      // Manually convert the "dd/MM/yyyy" format to "yyyy-MM-dd"
      String formattedDate = widget.expiryDate;
      List<String> dateParts = formattedDate.split('/');

      if (dateParts.length == 3) {
        // Reformat to "yyyy-MM-dd" format
        formattedDate =
            '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}'; // yyyy-MM-dd
      }

      // Now, use DateTime.parse() with the reformatted date
      expiryDate = DateTime.parse(formattedDate);

      // Check if expiryDate is null or invalid
      if (expiryDate == null) {
        return 'Invalid expiry date';
      }
    } catch (e) {
      return 'Invalid expiry date'; // Return an error message if parsing fails
    }

    // Calculate the difference in hours between the expiry date and the current time
    final int expiryDiffInHours = expiryDate.difference(DateTime.now()).inHours;

    // If the item is expired
    if (expiryDiffInHours < 0) {
      return 'Expired';
    }

    // If the item expires in less than 24 hours
    if (expiryDiffInHours < 24) {
      return 'This item expires in less than a day';
    }

    // If the item expires tomorrow
    final int expiryDiffInDays = expiryDate.difference(DateTime.now()).inDays;
    if (expiryDiffInDays == 1) {
      return 'This item expires tomorrow';
    }

    // If the item expires in more than 1 day
    return 'This item expires in: $expiryDiffInDays days';
  }

  void _requestDonation() {
    // Logic to request the donation
    setState(() {
      hasRequested = true; // Update the state to reflect the request
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonationRequestForm(
          productName: widget.productName,
          expiryDate: widget.expiryDate,
          donationId: widget.donationId,
          donorId: widget.donatorId,
          status: widget.status,
          donorName: widget.donorName,
          donatorId: widget.donatorId,
          donorImageUrl: widget.donorImageUrl,
          imageUrl: widget.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng donationLocation =
        LatLng(widget.donationLatitude, widget.donationLongitude);
    final LatLng userLocation =
        LatLng(widget.userLatitude, widget.userLongitude);

    double distanceInMeters = Geolocator.distanceBetween(
      widget.userLatitude,
      widget.userLongitude,
      widget.donationLatitude,
      widget.donationLongitude,
    );
    double distanceInMiles = distanceInMeters / 1609.34; // Convert to miles

    // Calculate time difference
    final timeDiff = DateTime.now().difference(widget.donationTime);

    // Check if the time difference is less than 24 hours
    String timeAgo;
    if (timeDiff.inHours < 24) {
      timeAgo = '${timeDiff.inHours} hours ago';
    } else {
      // Calculate days if more than 24 hours have passed
      int daysAgo = timeDiff.inDays;
      timeAgo = '$daysAgo days ago';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while checking request status
          : SingleChildScrollView(
              // Make the whole body scrollable
              child: Column(
                children: [
                  // Donation image at the top
                  widget.imageUrl.isNotEmpty
                      ? Container(
                          height: 200,
                          width: double.infinity,
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child; // Image is loaded, show it
                              } else {
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            (loadingProgress
                                                    .expectedTotalBytes ??
                                                1)
                                        : null,
                                  ),
                                ); // Show loading indicator while the image is loading
                              }
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/placeholder.png', // Placeholder image if error occurs
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        )
                      : Container(),

                  // Donation details section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display donor image and name with added time
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage:
                                  NetworkImage(widget.donorImageUrl),
                            ),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.donorName,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Added $timeAgo', // Display time since donation was added
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.productName,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _getTimeRemaining(), // Display the time remaining
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Status: ${widget.status}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 16),
                        Text(
                          'Pickup Times:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.pickupTimes,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Pickup Instructions:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.pickupInstructions,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      donorName: widget.donorName,
                                      userId: widget.userId,
                                      receiverEmail: widget.donorEmail,
                                      receiverId: widget.donatorId,
                                      donationId: widget.donationId,
                                      donationName: widget.productName,
                                      chatId: '',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: Text('Contact Donor',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            // Check if the user has already requested the item and display message accordingly
                            ElevatedButton(
                              onPressed: hasRequested
                                ? null // Disable button if request has already been made
                                : () =>
                                  _requestDonation(), // Enable if no request has been made
                              style: ElevatedButton.styleFrom(
                              backgroundColor:
                                hasRequested ? Colors.white : Colors.blue,
                              ),
                              child: Text(
                              hasRequested ? 'Request Sent' : 'Request Donation',
                              style: TextStyle(color: Colors.white), // Set text color to white
                              ),
                            )
                            ],
                          ),
                        SizedBox(height: 16),
                        Text(
                          'Scroll down to see the location',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Location and distance section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LOCATION', // Only display the simplified location address
                          style: TextStyle(fontSize: 14),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${distanceInMiles.toStringAsFixed(2)} miles away', // Display distance in miles
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),

                  // Map section with expandable functionality
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isMapExpanded = !isMapExpanded; // Toggle map expansion
                      });
                    },
                    child: Container(
                      height: isMapExpanded
                          ? MediaQuery.of(context).size.height
                          : 300, // Expand map to full screen or fixed height
                      width: double.infinity,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: donationLocation,
                          zoom: 14.0,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          mapController = controller;
                        },
                        markers: {
                          userMarker, // User's location marker
                        },
                        circles: {
                          Circle(
                            circleId: CircleId('radius'),
                            center: donationLocation,
                            radius: 150, // Define radius (500 meters)
                            strokeColor: Colors.blue.withOpacity(0.5),
                            strokeWidth: 2,
                            fillColor: Colors.blue.withOpacity(0.1),
                          ),
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  IconButton(
                    icon: Icon(isMapExpanded
                        ? Icons.remove
                        : Icons.add), // Change icon based on expansion state
                    onPressed: () {
                      setState(() {
                        isMapExpanded = !isMapExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
