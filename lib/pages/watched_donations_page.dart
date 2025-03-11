import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shelfaware_app/pages/user_donation_map.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/watched_donations_provider.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';
import 'package:shelfaware_app/services/user_service.dart';

class WatchedDonationsPage extends ConsumerStatefulWidget {
  final LatLng currentLocation;
  final UserService _userService = UserService();

  WatchedDonationsPage({
    required this.currentLocation,
  });

  @override
  _WatchedDonationsPageState createState() => _WatchedDonationsPageState();
}

class _WatchedDonationsPageState extends ConsumerState<WatchedDonationsPage> {
  LatLng? _userLocation;
  double? donorRating;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> fetchDonorRating(String donorId) async {
    double? rating = await widget._userService.fetchDonorRating(donorId);
    if (rating != null) {
     
        donorRating = rating;
      
    }
  }

  Future<void> _fetchUserLocation() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
        title: Text('Watched Donations'),
      ),
      body: watchedDonationsStream.when(
        data: (snapshot) {
          var donations = snapshot.docs;

          if (donations.isEmpty) {
            return Center(child: Text('No watched donations yet.'));
          }

          return ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              var donation = donations[index].data() as Map<String, dynamic>;
              String donationId = donations[index].id;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('donations')
                    .doc(donationId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var donationData = snapshot.data?.data() as Map<String, dynamic>?;
                  if (donationData == null) {
                    return Center(child: Text(''));
                  }

                  String productName = donationData['productName'] ?? 'No product name';
                  String status = donationData['status'] ?? 'Unknown';
                  String donorName = donationData['donorName'] ?? 'Anonymous';
                  String? imageUrl = donationData['imageUrl'];
                  Timestamp? expiryDate = donationData['expiryDate'];
                  GeoPoint? location = donationData['location'];
                  String donorId = donationData['donorId'] ?? '';
                  Timestamp? donationTime = donationData['addedOn'];
                  String pickupTimes = donationData['pickupTimes'] ?? 'Not specified';
                  String pickupInstructions = donationData['pickupInstructions'] ?? 'Not specified';

                  if (location == null) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          'Location unavailable for $productName',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text("Expiry date: ${expiryDate?.toDate() ?? 'Unknown'}"),
                        trailing: Text('$status'),
                      ),
                    );
                  }

                  double latitude = location.latitude;
                  double longitude = location.longitude;

                  String expiryText = expiryDate != null
                      ? "Expires on: ${DateFormat('dd/MM/yyyy').format(expiryDate.toDate())}"
                      : "Expiry date not available";

                  double distanceInMeters = Geolocator.distanceBetween(
                    currentLocation.latitude,
                    currentLocation.longitude,
                    latitude,
                    longitude,
                  );

                  double distanceInMiles = distanceInMeters / 1609.34;
                  String distanceText = "${(distanceInMiles).toStringAsFixed(2)} miles";

                  return FutureBuilder<bool>(
                    future: ref.read(watchedDonationsServiceProvider).isDonationInWatchlist(user.uid, donationId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      bool isInWatchlist = snapshot.data!;
                      fetchDonorRating(donorId);
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
                                final donorData = await ref.read(watchedDonationsServiceProvider).getDonorData(donorId);
                                final donorDataMap = donorData.data() as Map<String, dynamic>;
                                final profilePicUrl = donorDataMap['profileImageUrl'];

                                // Navigate to Donation Map screen with relevant data
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DonationMapScreen(
                                      donationLatitude: latitude,
                                      donationLongitude: longitude,
                                      userLatitude: currentLocation.latitude,
                                      userLongitude: currentLocation.longitude,
                                      productName: productName,
                                      expiryDate: DateFormat('yyyy-MM-dd').format(expiryDate!.toDate()),
                                      status: status,
                                      donorEmail: donorDataMap['email'] ?? 'Unknown',
                                      donatorId: donorId,
                                      chatId: 'chatId', // Replace with actual chatId if available
                                      userId: ref.read(authStateProvider).value!.uid,
                                      donorName: donorName,
                                      donorImageUrl: profilePicUrl,
                                      donationTime: donationTime!.toDate(),
                                      imageUrl: imageUrl ?? '',
                                      donationId: donations[index].id,
                                      receiverEmail: 'receiverEmail', // Replace with actual receiverEmail if available
                                      pickupTimes: pickupTimes,
                                      pickupInstructions: pickupInstructions,
                                      donorRating: donorRating ?? 0.0,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: imageUrl != null && imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => CircularProgressIndicator(),
                                              errorWidget: (context, url, error) => Icon(Icons.error),
                                            )
                                          : Image.asset(
                                              'assets/placeholder.png',
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            productName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              FutureBuilder<DocumentSnapshot>(
                                                future: ref.read(watchedDonationsServiceProvider).getDonorData(donorId),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return CircleAvatar(
                                                      radius: 18,
                                                      backgroundColor: Colors.grey[300],
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    );
                                                  }
                                                  if (snapshot.hasError || !snapshot.hasData) {
                                                    return CircleAvatar(
                                                      radius: 18,
                                                      backgroundColor: Colors.grey[300],
                                                      child: Icon(Icons.person, size: 18, color: Colors.grey),
                                                    );
                                                  }
                                                  final donorData = snapshot.data!.data() as Map<String, dynamic>;
                                                  final profilePicUrl = donorData['profileImageUrl'] ?? null;

                                                  return CircleAvatar(
                                                    radius: 18,
                                                    backgroundImage: profilePicUrl != null
                                                        ? CachedNetworkImageProvider(profilePicUrl)
                                                        : null,
                                                    backgroundColor: profilePicUrl == null ? Colors.grey[300] : Colors.transparent,
                                                    child: profilePicUrl == null ? Icon(Icons.person, size: 18, color: Colors.grey) : null,
                                                  );
                                                },
                                              ),
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
                                          StatusIconWidget(status: status),
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
                              child: FutureBuilder<bool>(
                                future: ref.read(watchedDonationsServiceProvider).isDonationInWatchlist(user.uid, donationId),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return CircularProgressIndicator();
                                  }
                                  bool isInWatchlist = snapshot.data!;
                                  return IconButton(
                                    icon: Icon(
                                      isInWatchlist ? Icons.star : Icons.star_border,
                                      color: isInWatchlist ? Colors.yellow : Colors.lightGreen,
                                      size: 24,
                                    ),
                                    onPressed: () async {
                                      await ref.read(watchedDonationsServiceProvider).toggleWatchlist(
                                          user.uid, donationId, donation);
                                    },
                                  );
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
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
