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
import 'package:shelfaware_app/repositories/user_repository.dart';
import 'package:shelfaware_app/services/user_service.dart';

import 'package:shelfaware_app/utils/donation_filter_calc_util.dart';

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
  final UserService _userService = UserService(UserRepository(
      firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance));
  Map<String, bool> watchlistStatus = {};
  Map<String, double> donorRatings = {};
  double averageRating = 0.0;
  bool filterExpiringSoon = false;
  bool filterNewlyAdded = false;
  double filterDistance = 0.0;

  @override
  void initState() {
    super.initState();
    filterExpiringSoon = widget.filterExpiringSoon;
    filterNewlyAdded = widget.filterNewlyAdded;
    filterDistance = widget.filterDistance;
  }

  void getDonorRating(String donorId) async {
    double? rating = await _userService.fetchDonorRating(donorId);
    if (rating != null) {
      setState(() {
        donorRatings[donorId] = rating;
      });
    }
  }

  Future<void> _refreshDonations() async {
    setState(() {});
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
          .orderBy('donatedAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

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

        if (donations.isEmpty ||
            donations.every((doc) =>
                (doc.data() as Map<String, dynamic>)['status'] == 'Picked Up')) {
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

        // Apply filters
        if (filterExpiringSoon || filterNewlyAdded || filterDistance > 0.0) {
          donations = donations.where((doc) {
            var donation = doc.data() as Map<String, dynamic>;
            if (filterExpiringSoon && !isExpiringSoon(donation['expiryDate'])) {
              return false;
            }
            if (filterNewlyAdded && !isNewlyAdded(donation['donatedAt'])) {
              return false;
            }
            if (filterDistance > 0.0) {
              GeoPoint? location = donation['location'];
              if (location != null) {
                double distanceInMeters = Geolocator.distanceBetween(
                  widget.currentLocation!.latitude,
                  widget.currentLocation!.longitude,
                  location.latitude,
                  location.longitude,
                );
                if (distanceInMeters / 1609.34 > filterDistance) {
                  return false;
                }
              }
            }
            return true;
          }).toList();
        }
        if (donations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No donations found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filter settings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshDonations,
          child: ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              var donation = donations[index].data() as Map<String, dynamic>;
              String status = donation['status'] ?? 'Unknown';

              if (status == 'Picked Up') {
                return Container();
              }

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildDonationCard(donation, donations[index].id, userId!),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation, String donationId, String userId) {
    // Extract all the existing donation card building logic here
    String productName = donation['productName'] ?? 'No product name';
    String donorName = donation['donorName'] ?? 'Anonymous';
    String? imageUrl = donation['imageUrl'];
    Timestamp? expiryDate = donation['expiryDate'];
    Timestamp? addedOn = donation['donatedAt'];
    GeoPoint? location = donation['location'];
    String donorId = donation['donorId'];
    
    getDonorRating(donorId);
    double? rating = donorRatings[donorId];
    
    double latitude = location?.latitude ?? 0.0;
    double longitude = location?.longitude ?? 0.0;

    ref.read(watchedDonationsServiceProvider)
        .isDonationInWatchlist(userId, donationId)
        .then((value) {
      if (watchlistStatus[donationId] != value) {
        setState(() {
          watchlistStatus[donationId] = value;
        });
      }
    });

    return DonationCard(
      // All existing DonationCard parameters remain the same
      productName: productName,
      status: donation['status'] ?? 'Unknown',
      donorName: donorName,
      donorId: donorId,
      donationId: donationId,
      imageUrl: imageUrl,
      expiryDate: expiryDate,
      location: LatLng(latitude, longitude),
      donorRating: rating,
      isNewlyAdded: isNewlyAdded(addedOn),
      isExpiringSoon: isExpiringSoon(expiryDate),
      currentLocation: widget.currentLocation!,
      isInWatchlist: watchlistStatus[donationId] ?? false,
      onTap: (String donationId) async {
        // Keep existing onTap implementation
        String donorImageUrl = await UserService(UserRepository(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance
        )).fetchDonorProfileImageUrl(donorId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonationMapScreen(
              // Keep existing DonationMapScreen parameters
              donationLatitude: latitude,
              donationLongitude: longitude,
              userLatitude: widget.currentLocation!.latitude,
              userLongitude: widget.currentLocation!.longitude,
              productName: productName,
              expiryDate: expiryDate != null 
                  ? DateFormat('dd/MM/yyyy').format(expiryDate.toDate())
                  : 'Unknown',
              status: donation['status'] ?? 'Unknown',
              donorName: donorName,
              chatId: '',
              userId: userId,
              receiverEmail: donation['donorEmail'],
              donatorId: donation['donorId'],
              donationId: donationId,
              donorEmail: donation['donorEmail'],
              imageUrl: donation['imageUrl']?.isNotEmpty ?? false
                  ? donation['imageUrl']
                  : 'assets/placeholder.png',
              donorImageUrl: donorImageUrl ?? '',
              donationTime: donation['donatedAt'].toDate(),
              pickupTimes: donation['pickupTimes'] ?? '',
              pickupInstructions: donation['pickupInstructions'] ?? '',
              donorRating: rating ?? 0.0,
            ),
          ),
        ).then((_) => _refreshDonations());
      },
      onWatchlistToggle: (String donationId) {
        // Keep existing onWatchlistToggle implementation
        setState(() {
          if (watchlistStatus[donationId] == true) {
            ref.read(watchedDonationsServiceProvider)
                .removeFromWatchlist(userId, donationId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.star_border, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Removed from watchlist"),
                  ],
                ),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ref.read(watchedDonationsServiceProvider)
                .addToWatchlist(userId, donationId, donation);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.star, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Added to watchlist"),
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: Colors.green),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WatchedDonationsPage(
                                  currentLocation: widget.currentLocation!),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
          }
        });
      },
    );
  }
}
