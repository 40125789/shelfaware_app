import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyFoodList extends StatelessWidget {
  const EmptyFoodList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://lottie.host/0505d746-774d-4081-a0cb-4b797aad8532/EjHnwNTimz.json',
            width: 200,
            height: 200,
            repeat: false,
          ),
          const SizedBox(height: 20),
          const Text(
            "Nothing here yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Add food items to get started',
            style: TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
