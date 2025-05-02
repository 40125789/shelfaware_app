import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

// Code adapted from:
// Mitch Koko. "Modern Login UI • Flutter Auth Tutorial." YouTube, 14 Oct. 2024, 
// https://www.youtube.com/watch?v=Dh-cTQJgM-Q


class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
//initially show login page
  bool showLoginPage = true;

//toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: togglePages,
        email: '',
      );
    } else {
      return RegisterPage(
        onTap: togglePages,
      );
    }
  }
}

