import 'package:flutter/material.dart';

class FoodHistorySortingFilteringDropdown extends StatelessWidget {
  final String filterOption;
  final ValueChanged<String?> onChanged;

  FoodHistorySortingFilteringDropdown({
    required this.filterOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      isExpanded: true,
      value: filterOption,
      items: [
        DropdownMenuItem<String>(
          value: 'Sort by Newest',
          child: Row(
            children: [
              Icon(Icons.arrow_downward),
              SizedBox(width: 8),
              Text('Sort by Newest'),
            ],
          ),
        ),
        DropdownMenuItem<String>(
          value: 'Sort by Oldest',
          child: Row(
            children: [
              Icon(Icons.arrow_upward),
              SizedBox(width: 8),
              Text('Sort by Oldest'),
            ],
          ),
        ),
        DropdownMenuItem<String>(
          value: 'Show Consumed',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline),
              SizedBox(width: 8),
              Text('Show Consumed'),
            ],
          ),
        ),
        DropdownMenuItem<String>(
          value: 'Show Discarded',
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 8),
              Text('Show Discarded'),
            ],
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}