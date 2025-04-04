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
  final Function(String donationId) onTap;
  final bool isInWatchlist;
  final Function(String donationId) onWatchlistToggle;

  const DonationCard({
    Key? key,
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
    required this.isInWatchlist,
    required this.onWatchlistToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Calculate distance
    final distanceText = _calculateDistance();
    
    // Calculate expiry information
    final expiryInfo = _calculateExpiryInfo();
    final isExpired = expiryInfo['isExpired'] as bool;
    final expiredTimeText = expiryInfo['text'] as String;

    // Define colors based on theme
    final cardColor = isExpired 
        ? (isDarkMode ? Colors.grey[800] : Colors.grey[200]) 
        : theme.cardColor;
    final textColor = isExpired
        ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
        : theme.textTheme.bodyLarge?.color;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isExpired ? BorderSide.none : BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
          color: cardColor,
          child: InkWell(
            onTap: isExpired ? null : () => onTap(donationId),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 120,
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(Icons.image_not_supported, 
                              color: secondaryTextColor, size: 40),
                          ),
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(Icons.image, color: secondaryTextColor, size: 40),
                        ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Product details
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
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        
                        // Donor info
                        Row(
                          children: [
                            ProfileImage(donorId: donorId, userId: ''),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                donorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (donorRating != null && donorRating! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 2),
                                    Text(
                                      donorRating!.toStringAsFixed(1),
                                      style: TextStyle(fontSize: 14, color: textColor),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Status
                        StatusIconWidget(status: status),
                        const SizedBox(height: 10),
                        
                        // Distance
                        Row(
                          children: [
                            Icon(Icons.location_on, color: secondaryTextColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              distanceText,
                              style: TextStyle(fontSize: 13, color: secondaryTextColor),
                            ),
                          ],
                        ),
                        
                        // Tags
                        if (!isExpired && (isNewlyAdded || isExpiringSoon)) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (isNewlyAdded)
                                _buildTag('New', Colors.green),
                              if (isExpiringSoon)
                                _buildTag('Expiring Soon', Colors.orange),
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
        
        // Expired overlay
        if (isExpired)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      expiredTimeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Watchlist button
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

  String _calculateDistance() {
    if (location != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        location.latitude,
        location.longitude,
      );
      double distanceInMiles = distanceInMeters / 1609.34;
      return "${distanceInMiles.toStringAsFixed(1)} miles away";
    }
    return "Unknown distance";
  }

  Map<String, dynamic> _calculateExpiryInfo() {
    String text = '';
    bool isExpired = false;

    if (expiryDate != null) {
      DateTime expiryDateTime = expiryDate!.toDate();
      DateTime today = DateTime.now();
      
      // Remove time component for accurate date comparison
      DateTime expiryOnly = DateTime(expiryDateTime.year, expiryDateTime.month, expiryDateTime.day);
      DateTime todayOnly = DateTime(today.year, today.month, today.day);

      int daysDifference = expiryOnly.difference(todayOnly).inDays;

      if (daysDifference < 0) {
        text = 'Expired';
        isExpired = true;
      }
    }

    return {'text': text, 'isExpired': isExpired};
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
    
