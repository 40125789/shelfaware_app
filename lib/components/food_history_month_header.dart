import 'package:flutter/material.dart';

class FoodHistoryMonthHeader extends StatelessWidget {
  final String month;

  FoodHistoryMonthHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          month,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
