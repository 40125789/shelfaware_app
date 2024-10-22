// filter_dropdown.dart
import 'package:flutter/material.dart';

class FilterDropdown extends StatelessWidget {
  final String selectedFilter;
  final List<String> filterOptions;
  final ValueChanged<String?> onChanged;

  const FilterDropdown({
    Key? key,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedFilter,
      onChanged: onChanged,
      items: filterOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
