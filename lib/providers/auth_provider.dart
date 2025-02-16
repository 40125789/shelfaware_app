
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/services/auth_services.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService().authStateChanges;  
});

class AuthState {
  final User? user;
  final bool isAuthenticated;

  AuthState({this.user, this.isAuthenticated = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription; // Store subscription

  AuthNotifier() : super(AuthState(isAuthenticated: false)) {
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      state = AuthState(user: user, isAuthenticated: user != null);

      
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthState(user: userCredential.user, isAuthenticated: true);
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      state = AuthState(user: null, isAuthenticated: false);
    } catch (e) {
      print("Error during sign-out: $e");
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // Cancel the listener when no longer needed
    super.dispose();
  }
}
