import 'package:flutter/material.dart';

class StatusIconWidget extends StatelessWidget {
  final String status;

  StatusIconWidget({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _getStatusIcon(status),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(
            color: _getStatusColor(status),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Available':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'Reserved':
        return Icon(Icons.hourglass_empty, color: Colors.orange);
      case 'Picked Up':
        return Icon(Icons.card_giftcard, color: Colors.blue);
      default:
        return Icon(Icons.help, color: Colors.grey);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Reserved':
        return Colors.orange;
      case 'Picked Up':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}