import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/donation_card.dart';
import 'package:shelfaware_app/pages/user_donation_map.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/watched_donations_provider.dart';
import 'package:shelfaware_app/repositories/user_repository.dart';
import 'package:shelfaware_app/services/user_service.dart';

class WatchedDonationsPage extends ConsumerStatefulWidget {
  final LatLng currentLocation;
  final UserService _userService = UserService(UserRepository(
      firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance));

  WatchedDonationsPage({
    required this.currentLocation,
  });

  @override
  _WatchedDonationsPageState createState() => _WatchedDonationsPageState();
}

class _WatchedDonationsPageState extends ConsumerState<WatchedDonationsPage>
    with SingleTickerProviderStateMixin {
  LatLng? _userLocation;
  Map<String, double> donorRatings = {};
  Map<String, String> donorProfileImages = {};
  late AnimationController _controller;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchDonorRating(String donorId) async {
    if (!donorRatings.containsKey(donorId)) {
      double? rating = await widget._userService.fetchDonorRating(donorId);
      if (rating != null) {
        setState(() {
          donorRatings[donorId] = rating;
        });
      }
    }
  }

  Future<void> fetchDonorProfileImage(String donorId) async {
    if (!donorProfileImages.containsKey(donorId)) {
      String? imageUrl = await widget._userService.fetchProfileImageUrl(donorId);
      if (imageUrl != null) {
        setState(() {
          donorProfileImages[donorId] = imageUrl;
        });
      }
    }
  }

  Future<void> _fetchUserLocation() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final GeoPoint? geoPoint = userData['location'];
        if (geoPoint != null) {
          setState(() {
            _userLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchedDonationsStream = ref.watch(watchedDonationsStreamProvider);
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return Center(child: Text('User not logged in.'));
    }

    final currentLocation = _userLocation ?? widget.currentLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Watched Donations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color:
                Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
      ),
      body: watchedDonationsStream.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
        data: (snapshot) {
          final donations = snapshot.docs;

          if (donations.isEmpty) {
            return FadeTransition(
              opacity: _controller,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No watched donations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start watching donations to see them here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return AnimatedList(
            key: _listKey,
            initialItemCount: donations.length,
            itemBuilder: (context, index, animation) {
              var donation = donations[index].data() as Map<String, dynamic>;
              String donationId = donations[index].id;

              return SlideTransition(
                position: animation.drive(Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOut))),
                child: FadeTransition(
                  opacity: animation,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('donations')
                        .doc(donationId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var donationData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      if (donationData == null) return SizedBox.shrink();

                      GeoPoint? location = donationData['location'];
                      if (location == null) return SizedBox.shrink();

                      String donorId = donationData['donorId'] ?? '';
                      if (donorId.isNotEmpty) {
                        fetchDonorRating(donorId);
                        fetchDonorProfileImage(donorId);
                      }

                      return DonationCard(
                        productName:
                            donationData['productName'] ?? 'No product name',
                        status: donationData['status'] ?? 'Unknown',
                        donorName: donationData['donorName'] ?? 'Anonymous',
                        imageUrl: donationData['imageUrl'],
                        donorId: donorId,
                        donationId: donationId,
                        expiryDate: donationData['expiryDate'],
                        addedOn: donationData['addedOn'],
                        location: LatLng(location.latitude, location.longitude),
                        donorRating: donorRatings[donorId],
                        isNewlyAdded: false,
                        isExpiringSoon: false,
                        currentLocation: currentLocation,
                        onTap: (String donId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DonationMapScreen(
                                donationLatitude: location.latitude,
                                donationLongitude: location.longitude,
                                userLatitude: currentLocation.latitude,
                                userLongitude: currentLocation.longitude,
                                productName: donationData['productName'] ??
                                    'No product name',
                                expiryDate: DateFormat('dd/MM/yyyy')
                                    .format(donationData['expiryDate'].toDate()),
                                status: donationData['status'] ?? 'Unknown',
                                donorEmail:
                                    donationData['donorEmail'] ?? 'Unknown',
                                donatorId: donorId,
                                chatId: 'chatId',
                                userId: ref.read(authStateProvider).value!.uid,
                                donorName:
                                    donationData['donorName'] ?? 'Anonymous',
                                donorImageUrl: donorProfileImages[donorId] ?? '',
                                donationTime: donationData['addedOn'].toDate(),
                                imageUrl: donationData['imageUrl'] ?? '',
                                donationId: donations[index].id,
                                receiverEmail: 'receiverEmail',
                                pickupTimes: donationData['pickupTimes'] ?? [],
                                pickupInstructions:
                                    donationData['pickupInstructions'] ?? '',
                                donorRating: donorRatings[donorId] ?? 0.0,
                              ),
                            ),
                          );
                        },
                        isInWatchlist: true,
                        onWatchlistToggle: (String donId) async {
                          await ref
                              .read(watchedDonationsServiceProvider)
                              .toggleWatchlist(user.uid, donId, donation);
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
