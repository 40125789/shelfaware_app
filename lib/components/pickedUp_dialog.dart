import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PickedUpPopup extends StatelessWidget {
  final VoidCallback onClose;

  const PickedUpPopup({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Sorry!" text at the top
            Text(
              "Sorry!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Changed text color to black
              ),
            ),
            SizedBox(height: 10),
            // Lottie animation with reduced size and centered
            SizedBox(
              width: 150, // Adjust this size as needed
              height: 150, // Adjust this size as needed
              child: Lottie.network(
                'https://lottie.host/fe3d8c46-b397-4367-ac2c-c81a53c08981/xy4z7PcXmA.json',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 10),
            // Text below the animation
            Text(
              "Item no longer available",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Changed text color to black
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
