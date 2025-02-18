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



class WatchedDonationsPage extends ConsumerWidget {
  final LatLng currentLocation;

  WatchedDonationsPage({
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchedDonationsStream = ref.watch(watchedDonationsStreamProvider);

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

              String productName = donation['productName'] ?? 'No product name';
              String status = donation['status'] ?? 'Unknown';
              String donorName = donation['donorName'] ?? 'Anonymous';
              String? imageUrl = donation['imageUrl'];
              Timestamp? expiryDate = donation['expiryDate'];
              GeoPoint? location = donation['location'];
              String donorId = donation['donorId'] ?? '';
              Timestamp? donationTime = donation['addedOn'];
              bool isWatched = donation['isWatched'] ?? false;

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

              Icon donationStatusIcon;
              Color statusColor;

              switch (status) {
                case 'available':
                  donationStatusIcon = Icon(Icons.check_circle, color: Colors.green);
                  statusColor = Colors.green;
                  break;
                case 'donated':
                  donationStatusIcon = Icon(Icons.card_giftcard, color: Colors.blue);
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
                              pickupTimes: '', // Replace with actual pickupTimes if available
                              pickupInstructions: '', // Replace with actual pickupInstructions if available
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
                          isWatched ? Icons.star : Icons.star_border,
                          color: isWatched ? Colors.yellow : Colors.lightGreen,
                          size: 24,
                        ),
                        onPressed: () async {
                          await ref.read(watchedDonationsServiceProvider).toggleWatchlist(
                              ref.read(authStateProvider).value!.uid, donations[index].id, donation);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Something went wrong. Please try again later.')),
      ),
    );
  }
}