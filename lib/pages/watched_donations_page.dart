import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WatchedDonationsPage extends StatelessWidget {
  final LatLng currentLocation;

  WatchedDonationsPage({required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Watched Donations'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('watched_donations')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var donations = snapshot.data!.docs;

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
              String? imageUrl = donation['imageUrl']; // Get the image URL
              Timestamp? expiryDate = donation['expiryDate'];
              GeoPoint? location = donation['location'];
              String donorId = donation['donorId'];
              Timestamp? donationTime = donation['addedOn'];
              bool isWatched = donation['isWatched'] ?? false; // Track if the donation is in the watchlist

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
                    subtitle:
                        Text("Expiry date: ${expiryDate?.toDate() ?? 'Unknown'}"),
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

              return Stack(
                children: [
                  Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 3, // Soft shadow to create depth
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                    child: InkWell(
                      onTap: () {
                        // Navigate to the donation map screen or any other details page
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
                                      width: 120, // Fixed width for image
                                      height: 120, // Full height
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
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
                                      fontSize: 18, // Larger font for product name
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8), // Space between product name and donor info

                                  // Donor's name and profile image (below product name)
                                  Row(
                                    children: [
                                      // Donor's profile image (small)
                                      FutureBuilder<DocumentSnapshot>( 
                                        future: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(donorId) // Donor's user ID as the document ID
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return CircleAvatar(
                                              radius: 18, // Smaller profile picture
                                              backgroundColor: Colors.grey[300],
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            );
                                          }
                                          if (snapshot.hasError || !snapshot.hasData) {
                                            return CircleAvatar(
                                              radius: 18, // Smaller profile picture
                                              backgroundColor: Colors.grey[300],
                                              child: Icon(Icons.person, size: 18, color: Colors.grey),
                                            );
                                          }
                                          final donorData = snapshot.data!.data() as Map<String, dynamic>;
                                          final profilePicUrl = donorData['profileImageUrl'] ?? null;

                                          return CircleAvatar(
                                            radius: 18, // Smaller profile picture
                                            backgroundImage: profilePicUrl != null
                                                ? CachedNetworkImageProvider(profilePicUrl)
                                                : null,
                                            backgroundColor: profilePicUrl == null
                                                ? Colors.grey[300]
                                                : Colors.transparent,
                                            child: profilePicUrl == null
                                                ? Icon(Icons.person, size: 18, color: Colors.grey)
                                                : null,
                                          );
                                        },
                                      ),
                                      SizedBox(width: 8), // Space between profile and name

                                      // Donor's name
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
                                  SizedBox(height: 8), // Space between donor info and status

                                  // Status (above miles info)
                                  Text(
                                    'Status: $status',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8), // Space between status and donation time

                                  // Miles info (at the bottom of the text area)
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
                      backgroundColor: Colors.transparent, // Transparent background
                      radius: 18, // Circle size
                      child: IconButton(
                        icon: Icon(
                          isWatched ? Icons.star : Icons.star_border, // Change icon based on watch status
                          color: isWatched ? Colors.yellow : Colors.lightGreen, // Change color
                          size: 24, // Adjust icon size as needed
                        ),
                        onPressed: () {
                          // Toggle watch status and update Firebase
                          FirebaseFirestore.instance
                              .collection('watched_donations')
                              .doc(donations[index].id)
                              .update({
                            'isWatched': !isWatched, // Toggle the watch status
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
      ),
    );
  }
}
