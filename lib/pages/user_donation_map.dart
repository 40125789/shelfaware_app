import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/components/donation_details_dialogue.dart';
import 'package:shelfaware_app/components/pickedUp_dialog.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/pages/donation_request_form.dart';
import 'package:shelfaware_app/providers/watched_donations_provider.dart'; // Ensure this import is correct
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/repositories/donation_request_repository.dart';
import 'package:shelfaware_app/utils/donation_time_calc_util.dart';
import 'package:shelfaware_app/utils/time_remaining_expiry_date.dart';
import 'package:shelfaware_app/utils/watchlist_helper.dart';

class DonationMapScreen extends ConsumerStatefulWidget {
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
  final double? donorRating;
 

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
  
    
    this.donorRating,
  });

  @override
  _DonationMapScreenState createState() => _DonationMapScreenState();
}

class _DonationMapScreenState extends ConsumerState<DonationMapScreen> {
  _DonationMapScreenState();
  late GoogleMapController mapController;
  late Circle donationMarker;
  late Marker userMarker;
  String address = 'Loading address...'; // Initialize with loading text
  bool isMapExpanded = false; // Manage the expanded state of the map
  bool hasRequested = false;
  bool isLoading = true; // Add a loading state
  late DonationRequestRepository _donationRequestRepository;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, bool> watchlistStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _getAddress();
    _checkIfAlreadyRequested();
    _checkWatchlistStatus();
  }

  void _checkWatchlistStatus() {
    print(
        "Checking watchlist status for user: ${widget.userId}, donation: ${widget.donationId}");

    ref
        .read(watchedDonationsServiceProvider)
        .isDonationInWatchlist(widget.userId, widget.donationId)
        .then((value) {
      print("Watchlist status for ${widget.donationId}: $value");

      // If the status is not already set in watchlistStatus, update it
      if (watchlistStatus[widget.donationId] != value) {
        setState(() {
          watchlistStatus[widget.donationId] = value;
        });
      }
    });
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
          donorName: widget.donorName,
          donationLatitude: widget.donationLatitude,
          donationLongitude: widget.donationLongitude,
          userLatitude: widget.userLatitude,
          userLongitude: widget.userLongitude,
          productName: widget.productName,
          expiryDate: widget.expiryDate,
          donationTime: widget.donationTime,
          pickupTimes: widget.pickupTimes,
          pickupInstructions: widget.pickupInstructions,
          donationId: widget.donationId,
          donatorId: widget.donatorId,
          donorEmail: widget.donorEmail,
          chatId: widget.chatId,
          donorImageUrl: widget.donorImageUrl,
          imageUrl: widget.imageUrl,
          status: widget.status,
          receiverEmail: '',
    

      

        );
      },
    );
  }

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
    return getTimeRemaining(widget.expiryDate);
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

    String timeAgo = calculateTimeAgo(widget.donationTime);

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(), // Show loading indicator
            )
          : Stack(
              children: [
                SingleChildScrollView(
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
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child; // Image loaded, show it
                                  } else {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
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
                                    'assets/placeholder.png', // Placeholder if error occurs
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // Align items on both sides
                              children: [
                                // Left side: Profile Image and Donor Name/Rating
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          NetworkImage(widget.donorImageUrl),
                                    ),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              widget.donorName,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            if (widget.donorRating != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        color: Colors.yellow,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        widget.donorRating!
                                                            .toStringAsFixed(1),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
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
                                              'Added $timeAgo',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Right side: Watchlist Star Icon
                                IconButton(
                                  icon: Icon(
                                    watchlistStatus[widget.donationId] ?? false
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: watchlistStatus[widget.donationId] ??
                                            false
                                        ? Colors.green
                                        : Colors.green,
                                  ),
                                  onPressed: () {
                                    toggleWatchlistStatus(
                                      context,
                                      widget.userId,
                                      widget.donationId,
                                      watchlistStatus,
                                      setState,
                                      ref,
                                      mounted,
                                    );
                                  },
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
                            StatusIconWidget(status: widget.status),
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
                                ElevatedButton(
                                  onPressed: hasRequested
                                      ? null
                                      : () => _requestDonation(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasRequested
                                        ? Colors.white
                                        : Colors.blue,
                                  ),
                                  child: Text(
                                    hasRequested
                                        ? 'Request Sent'
                                        : 'Request Donation',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Scroll down to see the location',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
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
                              'LOCATION',
                              style: TextStyle(fontSize: 14),
                            ),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  '${distanceInMiles.toStringAsFixed(2)} miles away',
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
                            isMapExpanded = !isMapExpanded;
                          });
                        },
                        child: Container(
                          height: isMapExpanded
                              ? MediaQuery.of(context).size.height
                              : 300,
                          width: double.infinity,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: donationLocation,
                              zoom: 14.0,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              mapController = controller;
                            },
                            markers: {userMarker},
                            circles: {
                              Circle(
                                circleId: CircleId('radius'),
                                center: donationLocation,
                                radius: 150,
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
                        icon: Icon(isMapExpanded ? Icons.remove : Icons.add),
                        onPressed: () {
                          setState(() {
                            isMapExpanded = !isMapExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (widget.status == 'Picked Up')
                  Positioned.fill(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ),
                        Center(
                          child: PickedUpPopup(
                            onClose: () {
                              setState(() {
                                // Add your logic here if needed
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
