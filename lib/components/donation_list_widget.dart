import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/pages/user_donation_map.dart';
import 'package:firebase_auth/firebase_auth.dart';  

class DonationListView extends StatelessWidget {
  final LatLng? currentLocation;

  DonationListView({this.currentLocation});

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return Center(child: CircularProgressIndicator());
    }

    // Get the current user's ID
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('donations').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Filter out donations made by the logged-in user
        var donations = snapshot.data!.docs.where((doc) {
          var donation = doc.data() as Map<String, dynamic>;
          return donation['donorId'] != userId;  // Exclude user's own donations
        }).toList();

        return ListView.builder(
          itemCount: donations.length,
          itemBuilder: (context, index) {
            var donation = donations[index].data() as Map<String, dynamic>;
            String productName = donation['productName'] ?? 'No product name';
            String status = donation['status'] ?? 'Unknown';
            Timestamp? expiryDate = donation['expiryDate'];
            GeoPoint? location = donation['location'];

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
                ? "Expires on: ${DateFormat('MM/dd/yyyy').format(expiryDate.toDate())}"
                : "Expiry date not available";

            double distanceInMeters = Geolocator.distanceBetween(
              currentLocation!.latitude,
              currentLocation!.longitude,
              latitude,
              longitude,
            );

            String distanceText =
                "${(distanceInMeters / 1000).toStringAsFixed(2)} km";

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

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: donationStatusIcon,
                ),
                title: Text(
                  productName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expiryText,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This item is: $status',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$distanceText away',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () {
                  // Navigate to the DonationMapScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationMapScreen(
                        donationLatitude: latitude,
                        donationLongitude: longitude,
                        userLatitude: currentLocation!.latitude,
                        userLongitude: currentLocation!.longitude,
                        productName: productName,
                        expiryDate: expiryDate != null
                            ? DateFormat('MM/dd/yyyy')
                                .format(expiryDate.toDate())
                            : 'Unknown',
                        status: status,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
