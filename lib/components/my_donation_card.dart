import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';

class MyDonationCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final int requestCount;
  final VoidCallback onTap;
  final String userId;
  final String assignedToName;

  const MyDonationCard({
    required this.donation,
    required this.requestCount,
    required this.onTap,
    required this.userId,
    required this.assignedToName,
  });

  @override
  Widget build(BuildContext context) {
    final productName = donation['productName'] ?? 'Unnamed Product';
    final donatedAt = donation['donatedAt'] as Timestamp?;
    final status = donation['status'] ?? 'Pending';
    final imageUrl = donation['imageUrl'] ?? '';
    final assignedToName = donation['assignedToName'] ?? '';

    final formattedDate = donatedAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(donatedAt.toDate())
        : 'Unknown Date';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        StatusIconWidget(status: status),
                        const SizedBox(height: 4),
                        Text(
                          "Date Added: $formattedDate",
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        if (status != 'Picked Up' && assignedToName.isNotEmpty)
                          Text(
                            "Reserved for: $assignedToName",
                            style: const TextStyle(color: Colors.green),
                          ),
                        const SizedBox(height: 8),
                        if (requestCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$requestCount request${requestCount != 1 ? 's' : ''}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (status == 'Picked Up')
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                  alignment: Alignment.center,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Donated',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}