import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shelfaware_app/components/watchlist_star_button.dart';
import 'package:shelfaware_app/services/profile_image_service.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';

class DonationCard extends ConsumerWidget {
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
  final Function(String donationId)
      onWatchlistToggle; // Callback for watchlist toggle

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
  Widget build(BuildContext context, WidgetRef ref) {
    late double distanceInMiles;
    late String distanceText;
    late String expiredTimeText;
    late bool isExpired;

    // Calculate distance
    if (location != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        location.latitude,
        location.longitude,
      );
      distanceInMiles = distanceInMeters / 1609.34;
      distanceText = "${distanceInMiles.toStringAsFixed(2)} miles away";
    } else {
      distanceText = "Unknown distance";
    }

// Calculate expiry time
expiredTimeText = '';
isExpired = false;

if (expiryDate != null) {
  DateTime expiryDateTime = expiryDate!.toDate();
  DateTime today = DateTime.now();
  
  // Remove time component for accurate date comparison
  DateTime expiryOnly = DateTime(expiryDateTime.year, expiryDateTime.month, expiryDateTime.day);
  DateTime todayOnly = DateTime(today.year, today.month, today.day);

  int daysDifference = expiryOnly.difference(todayOnly).inDays;

  if (daysDifference < 0) {
    expiredTimeText = 'Expired';
    isExpired = true;
  }
}

    final theme = Theme.of(context);
    final textColor = isExpired
        ? Colors.grey
        : theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Stack(
      children: [
      Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        ),
        color: isExpired ? Colors.grey[300] : theme.cardColor,
        child: InkWell(
        onTap: isExpired ? null : () => onTap(donationId),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                imageUrl: imageUrl!,
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
                color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                ProfileImage(donorId: donorId, userId: ''),
                SizedBox(width: 8),
                Text(
                  donorName,
                  style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 6),
                if (donorRating != null && donorRating! > 0)
                  Row(
                  children: [
                    Icon(Icons.star,
                      color: Colors.amber, size: 16),
                    Text(
                    donorRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14, color: textColor),
                    ),
                  ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              StatusIconWidget(status: status),
              SizedBox(height: 8),
              Row(
                children: [
                Icon(Icons.location_on,
                  color: Colors.grey, size: 16),
                SizedBox(width: 4),
                Text(
                  distanceText,
                  style: TextStyle(
                    fontSize: 12, color: Colors.grey[500]),
                ),
                ],
              ),
              if (!isExpired && (isNewlyAdded || isExpiringSoon)) ...[
                SizedBox(height: 8),
                Row(
                children: [
                  if (isNewlyAdded) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(
              Icons.access_time,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              expiredTimeText,
              style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            ],
          ),
          ),
        ),
        ),
    
      Positioned(
        bottom: 16,
        left: 16,
        child: WatchlistToggleButton(
          isInWatchlist: isInWatchlist,
          onToggle: () => onWatchlistToggle(donationId),
        ),
      ),
      ],
        );
      }
    }

    
    
