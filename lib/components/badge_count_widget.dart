import 'package:flutter/material.dart';

class Badge extends StatelessWidget {
  final int count;

  const Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Text(
        count.toString(),
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
