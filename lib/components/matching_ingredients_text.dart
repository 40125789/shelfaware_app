import 'package:flutter/material.dart';

class MatchingIngredientsText extends StatelessWidget {
  final int matchingCount;
  final int totalCount;

  const MatchingIngredientsText({
    Key? key,
    required this.matchingCount,
    required this.totalCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'You have $matchingCount out of $totalCount ingredients',
      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}