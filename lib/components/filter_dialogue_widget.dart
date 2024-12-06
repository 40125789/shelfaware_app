import 'package:flutter/material.dart';

class FilterDialog extends StatelessWidget {
  final List<double> distanceOptions;
  final double selectedDistance;
  final ValueChanged<double> onDistanceSelected;

  const FilterDialog({
    Key? key,
    required this.distanceOptions,
    required this.selectedDistance,
    required this.onDistanceSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Filter Donations"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Select Maximum Distance:"),
          ...distanceOptions.map((distance) {
            return ListTile(
              title: Text('$distance miles'),
              onTap: () {
                onDistanceSelected(distance);
                Navigator.of(context).pop(); // Close the dialog
              },
            );
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}
