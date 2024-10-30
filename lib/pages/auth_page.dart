import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import '../controllers/auth_controller.dart';
import 'home_page.dart';
import 'login_or_register_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: authController.authStateChanges,
        builder: (context, snapshot) {
          // Show a loading spinner while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If user is logged in, navigate to HomePage
          if (snapshot.hasData) {
            return HomePage();
          }

          // Otherwise, show LoginOrRegisterPage
          return LoginOrRegisterPage();
        },
      ),
    );
  }
}
