import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';

class MyDonationCard extends StatefulWidget {
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
    Key? key,
  }) : super(key: key);

  @override
  State<MyDonationCard> createState() => _MyDonationCardState();
}

class _MyDonationCardState extends State<MyDonationCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final productName = widget.donation['productName'] ?? 'Unnamed Product';
    final donatedAt = widget.donation['donatedAt'] as Timestamp?;
    final status = widget.donation['status'] ?? 'Pending';
    final imageUrl = widget.donation['imageUrl'] ?? '';
    final assignedToName = widget.donation['assignedToName'] ?? '';

    final formattedDate = donatedAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(donatedAt.toDate())
        : 'Unknown Date';

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: theme.cardColor,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'donation-image-${widget.donation['id'] ?? ''}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 120,
                                  height: 120,
                                  color: theme.disabledColor.withOpacity(0.1),
                                  child: Center(child: CircularProgressIndicator(color: colorScheme.secondary)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 120,
                                  height: 120,
                                  color: theme.disabledColor.withOpacity(0.1),
                                  child: Icon(Icons.image_not_supported, size: 40, color: theme.disabledColor),
                                ),
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                color: theme.disabledColor.withOpacity(0.1),
                                child: Icon(Icons.no_photography, size: 40, color: theme.disabledColor),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          StatusIconWidget(status: status),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: theme.hintColor),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (status != 'Picked Up' && assignedToName.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "Reserved for: $assignedToName",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          if (widget.requestCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${widget.requestCount} request${widget.requestCount != 1 ? 's' : ''}",
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
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
      ),
    );
  }
}
