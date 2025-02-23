import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/donation_provider.dart';

final requestStatusFilterProvider = StateProvider<String>((ref) => 'All');

class RequestStatusFilter extends ConsumerWidget {
  const RequestStatusFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: ref.watch(requestStatusFilterProvider),
        onChanged: (String? newValue) {
          ref.read(requestStatusFilterProvider.notifier).state = newValue!;
        },
        items: <String>['All', 'Pending', 'Accepted', 'Declined', 'Picked Up']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                _buildStatusBadge(value),
                const SizedBox(width: 8),
                Text(value),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData badgeIcon;

    switch (status) {
      case 'Pending':
        badgeColor = Colors.orange;
        badgeIcon = Icons.hourglass_empty;
        break;
      case 'Accepted':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        break;
      case 'Declined':
        badgeColor = Colors.red;
        badgeIcon = Icons.cancel;
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
      radius: 12,
      backgroundColor: badgeColor,
      child: Icon(
        badgeIcon,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}