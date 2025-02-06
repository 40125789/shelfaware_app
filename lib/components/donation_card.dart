import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shelfaware_app/services/profile_image_service.dart';



import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shelfaware_app/services/profile_image_service.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shelfaware_app/services/profile_image_service.dart';

class DonationCard extends StatefulWidget {
  final String productName;
  final String status;
  final String donorName;
  final String? imageUrl;
  final String donorId;
  final Timestamp? expiryDate;
  final Timestamp? addedOn;
  final LatLng location;
  final String donationId;
  final double? donorRating;
  final bool isNewlyAdded;
  final bool isExpiringSoon;
  final LatLng currentLocation;
  final Function(String donationId) onTap; // Callback for onTap event
  final bool isInWatchlist; // Add this line to include watchlist status
  final Function(String donationId) onWatchlistToggle; // Callback for watchlist toggle

  DonationCard({
    required this.productName,
    required this.status,
    required this.donorName,
    required this.donorId,
    required this.donationId,
    this.imageUrl,
    this.expiryDate,
    this.addedOn,
    required this.location,
    this.donorRating,
    required this.isNewlyAdded,
    required this.isExpiringSoon,
    required this.currentLocation,
    required this.onTap,
    required this.isInWatchlist, // Add this line to include watchlist status
    required this.onWatchlistToggle, // Add this line to include watchlist toggle callback
  });

  @override
  _DonationCardState createState() => _DonationCardState();
}

class _DonationCardState extends State<DonationCard> {
  late double distanceInMiles;
  late String distanceText;
  late String expiredTimeText;
  late bool isExpired;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        widget.currentLocation.latitude,
        widget.currentLocation.longitude,
        widget.location.latitude,
        widget.location.longitude,
      );
      distanceInMiles = distanceInMeters / 1609.34;
      distanceText = "${distanceInMiles.toStringAsFixed(2)} miles away";
    } else {
      distanceText = "Unknown distance";
    }

    // Calculate expired time and check if expired
    expiredTimeText = '';
    isExpired = false;
    if (widget.expiryDate != null) {
      var expiryDateTime = widget.expiryDate!.toDate();
      var difference = DateTime.now().difference(expiryDateTime);
      if (difference.isNegative) {
        expiredTimeText = 'Expires in ${-difference.inDays} days ${-difference.inHours % 24} hours';
      } else {
        expiredTimeText = 'Expired ${difference.inDays} days ${difference.inHours % 24} hours ago';
        isExpired = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isExpired ? Colors.grey : theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Stack(
      children: [
        Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isExpired ? Colors.grey[300]
          : theme.cardColor,
         // Change card color if expired and handle dark mode
          child: InkWell(
            onTap: isExpired ? null : () => widget.onTap(widget.donationId),
            // Handle onTap event
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Donation Image (left side)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/placeholder.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/placeholder.png',
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
                          widget.productName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),

                        // Donor's name and profile image (below product name)
                        Row(
                          children: [
                            ProfileImage(donorId: widget.donorId, userId: ''),
                            SizedBox(width: 8),
                            Text(
                              widget.donorName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Add some space between donor name and rating
                            SizedBox(width: 6),

                            // Display the average rating as gold stars
                            if (widget.donorRating != null && widget.donorRating! > 0)
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber, // Gold star
                                    size: 16,
                                  ),
                                  Text(
                                    widget.donorRating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Status: ${widget.status}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey, size: 16),
                            SizedBox(width: 4),
                            Text(
                              distanceText,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        if (!isExpired && (widget.isNewlyAdded || widget.isExpiringSoon)) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              if (widget.isNewlyAdded) ...[
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
                              if (widget.isExpiringSoon) ...[
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
        if (isExpired)
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  expiredTimeText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
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
                widget.isInWatchlist ? Icons.star : Icons.star_border,
                color: Colors.lightGreen,
                size: 24,
              ),
              onPressed: () => widget.onWatchlistToggle(widget.donationId),
            ),
          ),
        ),
      ],
    );
  }
}