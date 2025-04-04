import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/components/donation_details_dialogue.dart';
import 'package:shelfaware_app/components/pickedUp_dialog.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';
import 'package:shelfaware_app/components/watchlist_star_button.dart';
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
    required this.donorImageUrl,
    required this.donationTime,
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

class _DonationMapScreenState extends ConsumerState<DonationMapScreen>
    with SingleTickerProviderStateMixin {
  late GoogleMapController mapController;
  late Circle donationMarker;
  late Marker userMarker;
  String address = 'Loading location...';
  bool isMapExpanded = false;
  bool hasRequested = false;
  bool isLoading = true;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late DonationRequestRepository _donationRequestRepository;
  final _donationRequestService = DonationRequestRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, bool> watchlistStatus = {};

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _initializeMarkers();
    _getAddress();
    _checkIfAlreadyRequested();
    _checkWatchlistStatus();

    // Start animation after a short delay
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkWatchlistStatus() {
    ref
        .read(watchedDonationsServiceProvider)
        .isDonationInWatchlist(widget.userId, widget.donationId)
        .then((value) {
      if (mounted && watchlistStatus[widget.donationId] != value) {
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

    if (placemarks.isNotEmpty && mounted) {
      Placemark placemark = placemarks[0];
      setState(() {
        address = 'Location';
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
            receiverEmail: '');
      },
    );
  }

  Future<void> _checkIfAlreadyRequested() async {
    String userId = _auth.currentUser?.uid ?? '';
    try {
      bool alreadyRequested = await _donationRequestService
          .checkIfAlreadyRequested(widget.donationId, userId);
      if (mounted) {
        setState(() {
          hasRequested = alreadyRequested;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking donation request: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _getTimeRemaining() {
    return getTimeRemaining(widget.expiryDate);
  }

  void _requestDonation() {
    setState(() {
      hasRequested = true;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    double distanceInMeters = Geolocator.distanceBetween(
      widget.userLatitude,
      widget.userLongitude,
      widget.donationLatitude,
      widget.donationLongitude,
    );

    double distanceInMiles = distanceInMeters / 1609.34;
    String timeAgo = calculateTimeAgo(widget.donationTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Donation Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ??
                Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Donation image with hero animation
                      Hero(
                        tag: 'donation-${widget.donationId}',
                        child: Container(
                          height: 280, // Increased height to allow for overlap
                          width: double.infinity,
                          child: widget.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
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
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/placeholder.png',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Container(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[300],
                                  child: Icon(Icons.image_not_supported,
                                      size: 80,
                                      color: isDarkMode
                                          ? Colors.grey[600]
                                          : Colors.grey[600]),
                                ),
                        ),
                      ),

                      // Space for the details card to overlap
                      SizedBox(height: 40),
                    ],
                  ),
                ),

                // Overlapping details section with rounded corners
                SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 230), // Position for the overlap
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: Offset(0, -5),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left side: Profile Image and Donor Name/Rating
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundImage: NetworkImage(
                                              widget.donorImageUrl),
                                        ),
                                        SizedBox(width: 12),
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (widget.donorRating != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 8.0),
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .amber.shade800,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.star,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            widget.donorRating!
                                                                .toStringAsFixed(
                                                                    1),
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
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
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Watchlist button
                                    WatchlistToggleButton(
                                      isInWatchlist:
                                          watchlistStatus[widget.donationId] ??
                                              false,
                                      onToggle: () {
                                        bool newStatus = !(watchlistStatus[
                                                widget.donationId] ??
                                            false);
                                        toggleWatchlistStatus(
                                            context,
                                            widget.userId,
                                            widget.donationId,
                                            watchlistStatus,
                                            setState,
                                            ref,
                                            mounted);
                                        setState(() {
                                          watchlistStatus[widget.donationId] =
                                              newStatus;
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20),
                                Text(
                                  widget.productName,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.red.shade900.withOpacity(0.3)
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: isDarkMode
                                              ? Colors.red.shade700
                                              : Colors.red.shade200)),
                                  child: Text(
                                    _getTimeRemaining(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? Colors.red.shade300
                                          : Colors.red.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                StatusIconWidget(status: widget.status),
                                SizedBox(height: 20),
                                Divider(thickness: 1),
                                SizedBox(height: 20),

                                // Pickup details
                                _buildInfoSection(
                                  icon: Icons.schedule,
                                  title: 'Pickup Times',
                                  content: widget.pickupTimes,
                                  isDarkMode: isDarkMode,
                                ),
                                SizedBox(height: 16),
                                _buildInfoSection(
                                  icon: Icons.info_outline,
                                  title: 'Pickup Instructions',
                                  content: widget.pickupInstructions,
                                  isDarkMode: isDarkMode,
                                ),

                                SizedBox(height: 24),

                                // Action buttons
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChatPage(
                                                donorName: widget.donorName,
                                                userId: widget.userId,
                                                receiverEmail:
                                                    widget.donorEmail,
                                                receiverId: widget.donatorId,
                                                donationId: widget.donationId,
                                                donationName:
                                                    widget.productName,
                                                chatId: '',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.chat_bubble_outline,
                                            color: Colors.white),
                                        label: Text('Contact Donor',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: hasRequested
                                            ? null
                                            : () => _requestDonation(),
                                        icon: hasRequested
                                            ? Icon(Icons.check,
                                                color: Colors.grey)
                                            : Icon(Icons.shopping_bag_outlined,
                                                color: Colors.white),
                                        label: Text(
                                          hasRequested
                                              ? 'Request Sent'
                                              : 'Request Donation',
                                          style: TextStyle(
                                            color: hasRequested
                                                ? Colors.grey
                                                : Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: hasRequested
                                              ? (isDarkMode
                                                  ? Colors.grey[700]
                                                  : Colors.grey[200])
                                              : Colors.blue,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 24),

                                // Location info
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            address,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.blue[900]
                                              : Colors.blue[100],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${distanceInMiles.toStringAsFixed(1)} mi',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.blue[100]
                                                : Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 16),

                                // Animated map container
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  height: isMapExpanded
                                      ? MediaQuery.of(context).size.height * 0.6
                                      : 300,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        GoogleMap(
                                          initialCameraPosition: CameraPosition(
                                            target: donationLocation,
                                            zoom: 14.0,
                                          ),
                                          onMapCreated:
                                              (GoogleMapController controller) {
                                            mapController = controller;
                                            if (isDarkMode) {
                                              rootBundle
                                                  .loadString(
                                                      'assets/map_styles/dark_mode_map.json')
                                                  .then((mapStyle) {
                                                controller
                                                    .setMapStyle(mapStyle);
                                              });
                                            }
                                          },
                                          markers: {userMarker},
                                          circles: {
                                            Circle(
                                              circleId: CircleId('radius'),
                                              center: donationLocation,
                                              radius: 150,
                                              strokeColor:
                                                  Colors.blue.withOpacity(0.5),
                                              strokeWidth: 2,
                                              fillColor:
                                                  Colors.blue.withOpacity(0.1),
                                            ),
                                          },
                                          myLocationEnabled: true,
                                          myLocationButtonEnabled: true,
                                          zoomControlsEnabled: false,
                                        ),
                                        Positioned(
                                          bottom: 16,
                                          right: 16,
                                          child: FloatingActionButton.small(
                                            onPressed: () {
                                              setState(() {
                                                isMapExpanded = !isMapExpanded;
                                              });
                                            },
                                            child: Icon(isMapExpanded
                                                ? Icons.fullscreen_exit
                                                : Icons.fullscreen),
                                            backgroundColor: isDarkMode
                                                ? Colors.grey[800]
                                                : Colors.white,
                                            foregroundColor: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Picked up overlay
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

  // Helper method to build info sections with consistent styling
  Widget _buildInfoSection(
      {required IconData icon,
      required String title,
      required String content,
      required bool isDarkMode}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.blue.withOpacity(0.2)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
