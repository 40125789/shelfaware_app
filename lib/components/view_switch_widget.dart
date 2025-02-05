import 'package:flutter/material.dart';

class ViewSwitch extends StatelessWidget {
  final bool isToggled;
  final ValueChanged<bool> onChanged;

  ViewSwitch({
    required this.isToggled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          isToggled ? "Calendar view" : "List view",
          style: TextStyle(fontSize: 16),
        ),
        Switch(
          value: isToggled,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
