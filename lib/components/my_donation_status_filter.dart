import 'package:flutter/material.dart';

class StatusFilterWidget extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onStatusChanged;

  StatusFilterWidget({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedStatus,
      onChanged: (String? newValue) {
        if (newValue != null) {
          onStatusChanged(newValue);
        }
      },
      items: <String>['All', 'Available', 'Reserved', 'Picked Up']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              _buildStatusBadge(value),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: _getStatusColor(value),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

Widget _buildStatusBadge(String status) {
  Color badgeColor;
  IconData badgeIcon;

  switch (status) {
    case 'Available':
      badgeColor = Colors.green;
      badgeIcon = Icons.check_circle;
      break;
    case 'Reserved':
      badgeColor = Colors.orange;
      badgeIcon = Icons.hourglass_empty;
      break;
    case 'Picked Up':
      badgeColor = Colors.blue;
      badgeIcon = Icons.card_giftcard;
      break;
    default:
      badgeColor = Colors.grey;
      badgeIcon = Icons.help;
  }

  return CircleAvatar(
    key: Key('status-badge-$status'),  // Add a unique key for each status
    radius: 12,
    backgroundColor: badgeColor,
    child: Icon(
      badgeIcon,
      color: Colors.white,
      size: 16,
    ),
  );
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
