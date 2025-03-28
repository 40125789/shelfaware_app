import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';

class DonationProductDetails extends StatelessWidget {
  final String productName;
  final String imageUrl;
  final DateTime donatedAt;
  final String status;
  final String pickupDateTime;
  final String pickupInstructions;

  const DonationProductDetails({
    Key? key,
    required this.productName,
    required this.imageUrl,
    required this.donatedAt,
    required this.status,
    required this.pickupDateTime,
    required this.pickupInstructions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        _buildProductImage(),
        SizedBox(width: 16),
        // Product details
        Expanded(
          child: _buildProductInfo(context),
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        image: imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: imageUrl.isNotEmpty
          ? null
          : Center(
              child: Icon(Icons.image, size: 30, color: Colors.white),
            ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productName,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        _buildInfoRow(Icons.calendar_today,
            "Added: ${DateFormat('dd MMM yyyy').format(donatedAt)}"),
        SizedBox(height: 2),
        _buildInfoRow(Icons.access_time, "Pickup Time: $pickupDateTime"),
        SizedBox(height: 2),
        _buildInfoRow(
            Icons.info_outline, "Instructions: $pickupInstructions", true),
        SizedBox(height: 5),
        StatusIconWidget(status: status),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, [bool multiLine = false]) {
    return Row(
      crossAxisAlignment:
          multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700]),
            overflow: TextOverflow.visible,
            maxLines: multiLine ? 2 : 1,
          ),
        ),
      ],
    );
  }
}
