import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final User? user;
  final bool isAuthenticated;

  AuthState({this.user, this.isAuthenticated = false});
}
