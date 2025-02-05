import 'dart:math';

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
  final bool filterExpiringSoon;
  final bool filterNewlyAdded;
  final double filterDistance;

  DonationListView({
    this.currentLocation,
    required this.filterExpiringSoon,
    required this.filterNewlyAdded,
    required this.filterDistance,
  });

  @override
  _DonationListViewState createState() => _DonationListViewState();
}

class _DonationListViewState extends State<DonationListView> {
  late WatchlistService watchlistService;
  Map<String, bool> watchlistStatus = {};
  Map<String, double> donorRatings = {}; // Add this line to define donorRatings
  double averageRating = 0.0;
  bool filterExpiringSoon = false;
  bool filterNewlyAdded = false;
  double filterDistance = 0.0;
  

  @override
  void initState() {
    super.initState();
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    watchlistService =
        WatchlistService(userId: userId ?? ''); // Initialize WatchlistService
        

    // Initialize filter criteria from constructor arguments
    filterExpiringSoon = widget.filterExpiringSoon;
    filterNewlyAdded = widget.filterNewlyAdded;
    filterDistance = widget.filterDistance;
  }

  Future<void> fetchDonorRating(String donorId) async {
    if (donorRatings.containsKey(donorId)) return; // Avoid fetching if already fetched

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(donorId).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        var rating = data['averageRating'];
        if (rating != null) {
          setState(() {
            donorRatings[donorId] = rating.toDouble();
          });
        }
      }
    } catch (e) {
      print('Error fetching donor rating: $e');
    }
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

        // Initially, show all donations without any filter applied
        var donations = snapshot.data!.docs.where((doc) {
          var donation = doc.data() as Map<String, dynamic>;
          return donation['donorId'] != userId;
        }).toList();

        // Apply filters after initial load
        if (filterExpiringSoon || filterNewlyAdded || filterDistance > 0.0) {
          donations = donations.where((doc) {
            var donation = doc.data() as Map<String, dynamic>;

            // Apply 'Expiring Soon' filter
            if (filterExpiringSoon) {
              Timestamp? expiryDate = donation['expiryDate'];
              if (expiryDate != null) {
                var expiryDateTime = expiryDate.toDate();
                int daysUntilExpiry =
                    expiryDateTime.difference(DateTime.now()).inDays;
                if (daysUntilExpiry < 0 || daysUntilExpiry > 3) {
                  return false; // Filter out donations that are not expiring soon
                }
              }
            }

            // Apply 'Newly Added' filter
            if (filterNewlyAdded) {
              Timestamp? addedOn = donation['addedOn'];
              if (addedOn != null) {
                var addedDate = addedOn.toDate();
                if (DateTime.now().difference(addedDate).inHours >= 24) {
                  return false; // Filter out donations not added recently
                }
              }
            }

            // Apply 'Distance' filter
            if (filterDistance > 0.0) {
              GeoPoint? location = donation['location'];
              if (location != null) {
                double latitude = location.latitude;
                double longitude = location.longitude;

                double distanceInMeters = Geolocator.distanceBetween(
                  widget.currentLocation!.latitude,
                  widget.currentLocation!.longitude,
                  latitude,
                  longitude,
                );

                if (distanceInMeters / 1609.34 > filterDistance) {
                  return false; // Filter out donations beyond the specified distance
                }
              }
            }

            return true; // Include this donation if it passes all filters
          }).toList();
        }

        // Check if donations list is empty
        if (donations.isEmpty) {
          return Center(
            child: Text(
              'No donations match your filters!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        // Render ListView and filter out donations with the "Picked up" status
return donations.isEmpty
    ? Center(
        child: Text(
          "No donations yet!",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      )
    :

// Render ListView and filter out donations with the "Picked up" status
ListView.builder(
  itemCount: donations.length,
  itemBuilder: (context, index) {
    var donation = donations[index].data() as Map<String, dynamic>;
    String status = donation['status'] ?? 'Unknown';

    // Skip the donation if the status is "Picked up"
    if (status == 'Picked Up') {
      return Container(); // Return an empty container to skip this item
    }
        
            String productName = donation['productName'] ?? 'No product name';
            String donorName = donation['donorName'] ?? 'Anonymous';
            String? imageUrl = donation['imageUrl'];
            Timestamp? expiryDate = donation['expiryDate'];
            Timestamp? addedOn = donation['addedOn'];
            GeoPoint? location = donation['location'];
            String donorId = donation['donorId'];
            String donationId = donations[index].id;

           // Fetch the donor rating
            fetchDonorRating(donorId);

            // Fetch the average rating for the donor
             double? rating = donorRatings[donorId];

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

            // Calculate if the donation is "Newly Added" (within 24 hours)
            bool isNewlyAdded = false;
            if (addedOn != null) {
              var addedDate = addedOn.toDate();
              isNewlyAdded = DateTime.now().difference(addedDate).inHours < 24;
            }

            // Calculate if the donation is "Expiring Soon" (within 3 days)
            bool isExpiringSoon = false;
            if (expiryDate != null) {
              var expiryDateTime = expiryDate.toDate();
              int daysUntilExpiry =
                  expiryDateTime.difference(DateTime.now()).inDays;
              isExpiringSoon = daysUntilExpiry >= 0 && daysUntilExpiry <= 3;
            }

            return Stack(
              children: [
                Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () async {
                      // Fetch the profile image URL
                      var userData = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(donation['donorId'])
                          .get();
                      String donorImageUrl = userData.exists
                          ? userData['profileImageUrl'] ?? ''
                          : '';

                      try {
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
                              imageUrl:
                                  donation['imageUrl']?.isNotEmpty ?? false
                                      ? donation['imageUrl']
                                      : 'assets/placeholder.png',
                              donorImageUrl: donorImageUrl,
                              donationTime: donation['addedOn'].toDate(),
                            ),
                          ),
                        );
                      } catch (e) {
                        print('Error getting location: $e');
                        // Optionally show a message to the user
                      }
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
                    errorWidget: (context, url, error) => Image.asset(
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
                SizedBox(height: 8),

                // Donor's name and profile image (below product name)
                Row(
                  children: [
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

                       // Add some space between donor name and rating
                     SizedBox(width: 6),

                    // Display the average rating as gold stars
                                    if (rating != null && rating > 0)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.amber, // Gold star
                                            size: 16,
                                          ),
                                          Text(
                                            rating.toStringAsFixed(1), // Display rating with 1 decimal point
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
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
                if (isNewlyAdded || isExpiringSoon) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      if (isNewlyAdded) ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'New',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                      if (isExpiringSoon) ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Expiring Soon',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
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
                            watchlistService.addToWatchlist(
                                donationId, donation);
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


