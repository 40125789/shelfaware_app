import 'package:flutter/material.dart';
import 'package:shelfaware_app/pages/home_page.dart';
// Replace with your main screen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadMainScreen();
  }

  Future<void> _loadMainScreen() async {
    // Simulate loading process (e.g., API calls, local data fetching)
    await Future.delayed(Duration(seconds: 3));

    // Navigate to the main screen after loading
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),  // Replace with your main screen widget
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Customize background color
      body: Center(
        child: Image.asset('assets/splashscreen/splashscreen.png'),  // Show your splash image
      ),
    );
  }
}
