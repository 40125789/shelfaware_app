import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'home_page.dart';
import 'login_or_register_page.dart';

// Code adapted from:
// Mitch Koko. "Modern Login UI • Flutter Auth Tutorial." YouTube, 14 Oct. 2024, 
// https://www.youtube.com/watch?v=Dh-cTQJgM-Q


class AuthPage extends ConsumerWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: authState.isAuthenticated
          ? HomePage() // Redirect to HomePage if authenticated
          : LoginOrRegisterPage(), // Otherwise, show login/register page
    );
  }
}
