import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';
import 'package:shelfaware_app/components/watchlist_star_button.dart';
import 'package:shelfaware_app/screens/user_donation_map.dart';
import 'package:shelfaware_app/repositories/user_repository.dart';
import 'package:shelfaware_app/repositories/watched_donations_repository.dart';
import 'package:shelfaware_app/services/user_service.dart';
import 'package:shelfaware_app/services/watched_donations_service.dart';

class DonationDetailsDialog extends StatefulWidget {
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
  final String donorImageUrl;
  final DateTime donationTime;
  final String pickupTimes;
  final String pickupInstructions;

  DonationDetailsDialog({
    Key? key,
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
    required this.donorName,
    required this.donorImageUrl,
    required this.donationTime,
    required this.imageUrl,
    required this.donationId,
    required this.pickupTimes,
    required this.pickupInstructions,
    required String receiverEmail,
  }) : super(key: key);

  @override
  _DonationDetailsDialogState createState() => _DonationDetailsDialogState();
}

class _DonationDetailsDialogState extends State<DonationDetailsDialog> {
  double? donorRating;
  final UserService _userService = UserService(UserRepository(
      auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance));
  final WatchedDonationsService watchedDonationsService =
      WatchedDonationsService(WatchedDonationsRepository(
          firebaseFirestore: FirebaseFirestore.instance,
          firebaseAuth: FirebaseAuth.instance));

  bool isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    fetchDonorRating();
    checkWatchlistStatus();
  }

  Future<void> fetchDonorRating() async {
    double? rating = await _userService.fetchDonorRating(widget.donatorId);
    setState(() {
      donorRating = rating;
    });
  }

  Future<void> checkWatchlistStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid.isEmpty) {
      print("Error: No authenticated user found.");
      return;
    }

    bool status = await watchedDonationsService.isDonationInWatchlist(
        user.uid, widget.donationId);

    setState(() {
      isInWatchlist = status;
    });
  }

  void toggleWatchlist() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (isInWatchlist) {
      await watchedDonationsService.removeFromWatchlist(
          FirebaseAuth.instance.currentUser!.uid, widget.donationId);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.star_border, color: Colors.white),
              SizedBox(width: 8),
              Text("Removed from watchlist"),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      await watchedDonationsService.addToWatchlist(
          FirebaseAuth.instance.currentUser!.uid, widget.donationId, {});
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.star, color: Colors.white),
              SizedBox(width: 8),
              Text("Added to watchlist"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    setState(() {
      isInWatchlist = !isInWatchlist;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate a better height based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.75; // Use 75% of screen height

    return Container(
      constraints: BoxConstraints(
        maxHeight: dialogHeight,
        minHeight: 450, // Ensure minimum height to show buttons
      ),
      child: Card(
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image at the top with fixed height
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.broken_image,
                              size: 50, color: Colors.grey.shade400),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey.shade400),
                      ),
              ),

              // Details below image
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name and info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        StatusIconWidget(status: widget.status),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Donor info
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Donor:',
                      value: widget.donorName,
                      trailing: donorRating != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 3),
                                Text(
                                  donorRating!.toStringAsFixed(1),
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            )
                          : null,
                    ),

                    SizedBox(height: 8),

                    // Expiry
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Expiry:',
                      value: widget.expiryDate,
                      valueColor: _getExpiryColor(widget.expiryDate),
                    ),

                    SizedBox(height: 8),

                    // Posted time
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Posted:',
                      value: DateFormat('MMM d, yyyy • h:mm a')
                          .format(widget.donationTime),
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1, thickness: 1),
                    ),

                    // Pickup info preview
                    if (widget.pickupTimes.isNotEmpty ||
                        widget.pickupInstructions.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            iconTheme: IconThemeData(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.pickupTimes.isNotEmpty) ...[
                                _buildInfoRow(
                                  icon: Icons.schedule,
                                  label: 'Pickup times:',
                                  value: widget.pickupTimes,
                                  valueColor: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                SizedBox(height: 6),
                              ],
                              if (widget.pickupInstructions.isNotEmpty)
                                _buildInfoRow(
                                  icon: Icons.info,
                                  label: 'Instructions:',
                                  value: widget.pickupInstructions,
                                  valueColor: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                  maxLines: 2,
                                ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 24), // Increased spacing before buttons

                    // Action buttons - moved to bottom with clear spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        WatchlistToggleButton(
                          isInWatchlist: isInWatchlist,
                          onToggle: toggleWatchlist,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                backgroundColor: Theme.of(context).primaryColor,
                                elevation: 2,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DonationMapScreen(
                                      donationLatitude: widget.donationLatitude,
                                      donationLongitude:
                                          widget.donationLongitude,
                                      userLatitude: widget.userLatitude,
                                      userLongitude: widget.userLongitude,
                                      productName: widget.productName,
                                      expiryDate: widget.expiryDate,
                                      status: widget.status,
                                      donorName: widget.donorName,
                                      chatId: widget.chatId,
                                      donorEmail: widget.donorEmail,
                                      donatorId: widget.donatorId,
                                      donationId: widget.donationId,
                                      imageUrl: widget.imageUrl,
                                      donorImageUrl: widget.donorImageUrl,
                                      donationTime: widget.donationTime,
                                      pickupTimes: widget.pickupTimes,
                                      pickupInstructions:
                                          widget.pickupInstructions,
                                      receiverEmail: '',
                                      userId: FirebaseAuth
                                          .instance.currentUser!.uid,
                                      donorRating: donorRating ?? 0.0,
                                    ),
                                  ),
                                ).then((_) {
                                  fetchDonorRating();
                                  checkWatchlistStatus();
                                });
                              },
                              icon: Icon(Icons.map, color: Colors.white),
                              label: Text('View Details',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8), // Add space at the bottom
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getExpiryColor(String expiryDate) {
    try {
      final expiry = DateFormat('yyyy-MM-dd').parse(expiryDate);
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;

      if (difference < 0) return Colors.red;
      if (difference < 3) return Colors.orange;
      return Colors.green;
    } catch (e) {
      return Colors.red;
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Color? valueColor,
    Widget? trailing,
    Widget? custom,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(width: 4),
        custom != null
            ? custom
            : Expanded(
                child: Text(
                  value ?? "",
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor,
                    fontWeight: valueColor != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: maxLines,
                ),
              ),
        if (trailing != null) trailing,
      ],
    );
  }
}
