import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelfaware_app/pages/login_page.dart';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shelfaware_app/pages/login_page.dart';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shelfaware_app/pages/login_page.dart';

class RegistrationSuccessPage extends StatelessWidget {
  final String firstName;
  final String email;

  const RegistrationSuccessPage(
      {super.key, required this.firstName, required this.email});

  @override
  Widget build(BuildContext context) {
    // Delayed redirection after the build phase is completed
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(email: email, onTap: () {  },),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Success'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Lottie.asset(
                'assets/animations/register_success.json',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 20),
              // Welcome message with the user's first name
              Text(
                'Welcome, $firstName!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              // Verification message
              Text(
                'A verification email has been sent to your $email! Please verify your email before logging in.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
