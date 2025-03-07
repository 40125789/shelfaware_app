import 'package:flutter/material.dart';

class RatingRow extends StatelessWidget {
  final String label;
  final double rating;

  RatingRow({required this.label, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Icon(Icons.star, color: Colors.yellow, size: 16),
        Text('${rating.toStringAsFixed(1)}'),
      ],
    );
  }
}