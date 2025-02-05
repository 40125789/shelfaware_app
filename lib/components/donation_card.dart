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
  final GeoPoint? location;
  final String donationId;
  final double? donorRating;
  final bool isNewlyAdded;
  final bool isExpiringSoon;
  final LatLng currentLocation;
  final Function(String donationId) onTap; // Callback for onTap event

  DonationCard({
    required this.productName,
    required this.status,
    required this.donorName,
    required this.donorId,
    required this.donationId,
    this.imageUrl,
    this.expiryDate,
    this.addedOn,
    this.location,
    this.donorRating,
    required this.isNewlyAdded,
    required this.isExpiringSoon,
    required this.currentLocation,
    required this.onTap,
  });

  @override
  _DonationCardState createState() => _DonationCardState();
}

class _DonationCardState extends State<DonationCard> {
  late double distanceInMiles;
  late String distanceText;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        widget.currentLocation.latitude,
        widget.currentLocation.longitude,
        widget.location!.latitude,
        widget.location!.longitude,
      );
      distanceInMiles = distanceInMeters / 1609.34;
      distanceText = "${distanceInMiles.toStringAsFixed(2)} miles";
    } else {
      distanceText = "Unknown distance";
    }
  }

  @override
  Widget build(BuildContext context) {
   

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => widget.onTap(widget.donationId), // Handle onTap event
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
                                  color: Colors.grey[700],
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
                          widget.isNewlyAdded || widget.isExpiringSoon
                              ? '${widget.isNewlyAdded ? 'New' : 'Expiring soon'}'
                              : '$distanceText away',
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
    );
  }
}
