import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:shelfaware_app/components/donation_card.dart';
import 'package:shelfaware_app/pages/user_donation_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/pages/watched_donations_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/watched_donations_provider.dart';
import 'package:shelfaware_app/services/user_service.dart';




class DonationListView extends ConsumerStatefulWidget {
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

class _DonationListViewState extends ConsumerState<DonationListView> {
  final UserService _userService = UserService();
  Map<String, bool> watchlistStatus = {};
  Map<String, double> donorRatings = {};
  double averageRating = 0.0;
  bool filterExpiringSoon = false;
  bool filterNewlyAdded = false;
  double filterDistance = 0.0;

  @override
  void initState() {
    super.initState();

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
      stream: FirebaseFirestore.instance
        .collection('donations')
        .orderBy('addedOn', descending: true)
        .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        // Initially, show all donations within a 10-mile radius by default
        var donations = snapshot.data!.docs.where((doc) {
          var donation = doc.data() as Map<String, dynamic>;
          if (donation['donorId'] == userId) return false;

          GeoPoint? location = donation['location'];
          if (location != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              widget.currentLocation!.latitude,
              widget.currentLocation!.longitude,
              location.latitude,
              location.longitude,
            );
            double distanceInMiles = distanceInMeters / 1609.34;
            return distanceInMiles <= 10.0;
          }
          return false;
        }).toList();

        if (donations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.network(
                      'https://lottie.host/fb6c778f-ef74-4a0b-a0b1-74658a49b5b8/MfI0YXgMZ1.json'),
                ),
                SizedBox(height: 20),
                Text(
                  'No donations available within your local area!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

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

        return ListView.builder(
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
            ref
                .read(watchedDonationsServiceProvider)
                .isDonationInWatchlist(userId!, donationId)
                .then((value) {
                if (watchlistStatus[donationId] != value) {
                  setState(() {
                    watchlistStatus[donationId] = value;
                  });
                }
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

            return DonationCard(
              productName: productName,
              status: status,
              donorName: donorName,
              donorId: donorId,
              donationId: donationId,
              imageUrl: imageUrl,
              expiryDate: expiryDate,
              location: LatLng(latitude, longitude),
              donorRating: rating,
              isNewlyAdded: isNewlyAdded,
              isExpiringSoon: isExpiringSoon,
              currentLocation: widget.currentLocation!,
              onTap: (String donationId) async {
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
                        imageUrl: donation['imageUrl']?.isNotEmpty ?? false
                            ? donation['imageUrl']
                            : 'assets/placeholder.png',
                        donorImageUrl: donorImageUrl ?? '',
                        donationTime: donation['addedOn'].toDate(),
                        pickupTimes: donation['pickupTimes'] ?? '',
                        pickupInstructions: donation['pickupInstructions'] ?? '',
                      ),
                    ),
                  );
                } catch (e) {
                  print('Error getting location: $e');
                  // Optionally show a message to the user
                }
              },
                isInWatchlist: watchlistStatus[donationId] ?? false,
                onWatchlistToggle: (String donationId) {
                setState(() {
                  if (watchlistStatus[donationId] == true) {
                  ref
                    .read(watchedDonationsServiceProvider)
                    .removeFromWatchlist(userId, donationId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: Row(
                      children: [
                      Icon(
                        Icons.star_border,
                        color: Colors.green,
                      ),
                            SizedBox(width: 8),
                            Text("Removed from watchlist"),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ref
                        .read(watchedDonationsServiceProvider)
                        .addToWatchlist(userId, donationId, donation);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar() // Hides any active Snackbar
                      ..showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text("Added to watchlist"),
                              IconButton(
                                icon: Icon(Icons.arrow_forward, color: Colors.green),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WatchedDonationsPage(currentLocation: widget.currentLocation!),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          duration: Duration(seconds: 2), // Ensures auto-dismiss
                        ),
                      );
                  }
                });
              },
            );
          },
        );
      },
    );
  }
}
