import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';
import 'package:shelfaware_app/components/watchlist_star_button.dart';
import 'package:shelfaware_app/pages/user_donation_map.dart';
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

  // Watchlist state
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

    print(
        "Checking watchlist status for user: ${user.uid}, donation: ${widget.donationId}");

    bool status = await watchedDonationsService.isDonationInWatchlist(
        user.uid, widget.donationId);

    setState(() {
      isInWatchlist = status;
    });
  }

  void toggleWatchlist() async {
    if (isInWatchlist) {
      await watchedDonationsService.removeFromWatchlist(
          FirebaseAuth.instance.currentUser!.uid, widget.donationId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.star_border, color: Colors.red),
              SizedBox(width: 8),
              Text("Removed from watchlist"),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      await watchedDonationsService.addToWatchlist(
          FirebaseAuth.instance.currentUser!.uid, widget.donationId, {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.star, color: Colors.green),
              SizedBox(width: 8),
              Text("Added to watchlist"),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      isInWatchlist = !isInWatchlist;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrl,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Donor:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          Text(
                            widget.donorName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (donorRating != null) ...[
                            SizedBox(width: 5),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 3),
                            Text(donorRating!.toStringAsFixed(1)),
                          ],
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Expiry:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          Text(
                            widget.expiryDate,
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Status:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          StatusIconWidget(status: widget.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WatchlistToggleButton(
                  isInWatchlist: isInWatchlist,
                  onToggle: toggleWatchlist,
                ),
                Expanded(
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DonationMapScreen(
                              donationLatitude: widget.donationLatitude,
                              donationLongitude: widget.donationLongitude,
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
                              pickupInstructions: widget.pickupInstructions,
                              receiverEmail: '',
                              userId: FirebaseAuth.instance.currentUser!.uid,
                              donorRating: donorRating ?? 0.0,
                            ),
                          ),
                        ).then((_) {
                          // Refresh data when coming back from the map screen
                          fetchDonorRating();
                          checkWatchlistStatus();
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info, color: Colors.white),
                          SizedBox(width: 5),
                          Text('View Details',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
