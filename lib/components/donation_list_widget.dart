import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/pages/user_donation_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shelfaware_app/services/profile_image_service.dart';
import 'package:shelfaware_app/services/watched_donation_service.dart';

class DonationListView extends StatefulWidget {
  final LatLng? currentLocation;

  DonationListView({this.currentLocation});

  @override
  _DonationListViewState createState() => _DonationListViewState();
}

class _DonationListViewState extends State<DonationListView> {
  late WatchlistService watchlistService;
  Map<String, bool> watchlistStatus = {};
  Map<String, String?> donorProfileImageUrl = {};

  @override
  void initState() {
    super.initState();
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    watchlistService = WatchlistService(userId: userId ?? ''); // Initialize WatchlistService
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentLocation == null) {
      return Center(child: CircularProgressIndicator());
    }

    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('donations').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var donations = snapshot.data!.docs.where((doc) {
          var donation = doc.data() as Map<String, dynamic>;
          return donation['donorId'] != userId;
        }).toList();

        return ListView.builder(
          itemCount: donations.length,
          itemBuilder: (context, index) {
            var donation = donations[index].data() as Map<String, dynamic>;
            String productName = donation['productName'] ?? 'No product name';
            String status = donation['status'] ?? 'Unknown';
            String donorName = donation['donorName'] ?? 'Anonymous';
            String? imageUrl = donation['imageUrl']; // Get the image URL
            Timestamp? expiryDate = donation['expiryDate'];
            GeoPoint? location = donation['location'];
            String donorId = donation['donorId'];
            String donationId = donations[index].id;

            double latitude = location?.latitude ?? 0.0;
            double longitude = location?.longitude ?? 0.0;

            String expiryText = expiryDate != null
                ? "Expires on: ${DateFormat('dd/MM/yyyy').format(expiryDate.toDate())}"
                : "Expiry date not available";

            double distanceInMeters = Geolocator.distanceBetween(
              widget.currentLocation!.latitude,
              widget.currentLocation!.longitude,
              latitude,
              longitude,
            );

            double distanceInMiles = distanceInMeters / 1609.34;
            String distanceText =
                "${(distanceInMiles).toStringAsFixed(2)} miles";

            Icon donationStatusIcon;
            Color statusColor;

            switch (status) {
              case 'available':
                donationStatusIcon =
                    Icon(Icons.check_circle, color: Colors.green);
                statusColor = Colors.green;
                break;
              case 'donated':
                donationStatusIcon =
                    Icon(Icons.card_giftcard, color: Colors.blue);
                statusColor = Colors.blue;
                break;
              case 'expired':
                donationStatusIcon = Icon(Icons.cancel, color: Colors.red);
                statusColor = Colors.red;
                break;
              default:
                donationStatusIcon = Icon(Icons.help, color: Colors.grey);
                statusColor = Colors.grey;
            }

            // Watchlist logic
            watchlistService.isDonationInWatchlist(donationId).then((value) {
              setState(() {
                watchlistStatus[donationId] = value;
              });
            });

            return Stack(
              children: [
                Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DonationMapScreen(
                            donationLatitude: latitude,
                            donationLongitude: longitude,
                            userLatitude: widget.currentLocation!.latitude,
                            userLongitude: widget.currentLocation!.longitude,
                            productName: productName,
                            expiryDate: expiryDate != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(expiryDate.toDate())
                                : 'Unknown',
                            status: status,
                            donorName: donorName,
                            chatId: '',
                            userId: '',
                            receiverEmail: donation['donorEmail'],
                            donatorId: donation['donorId'],
                            donationId: donationId,
                            donorEmail: donation['donorEmail'],
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Donation Image (left side)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        Image.asset(
                                          'assets/placeholder.png',
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                  )
                                : Image.asset(
                                    'assets/placeholder.png', // Placeholder image
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          SizedBox(width: 12), // Space between image and text

                          // Text area (right side)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Name (top of the text area)
                                Text(
                                  productName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8), // Space between product name and donor info

                                // Donor's name and profile image (below product name)
                                Row(
                                  children: [
                                    // Donor's profile image (small)
      ProfileImage(donorId: donorId, userId: userId ?? ''),
      SizedBox(width: 8),
      Text(
        donorName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, color: Colors.grey, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '$distanceText away',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 18,
                    child: IconButton(
                      icon: Icon(
                        watchlistStatus[donationId] ?? false
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.lightGreen,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          if (watchlistStatus[donationId] == true) {
                            watchlistService.removeFromWatchlist(donationId);
                          } else {
                            watchlistService.addToWatchlist(donationId, donation);
                          }
                          watchlistStatus[donationId] =
                              !(watchlistStatus[donationId] ?? false);
                        });
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
