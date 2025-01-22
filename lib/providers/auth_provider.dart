
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthState {
  final User? user;
  final bool isAuthenticated;

  AuthState({this.user, this.isAuthenticated = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthNotifier() : super(AuthState(isAuthenticated: false)) {
    _firebaseAuth.authStateChanges().listen((user) {
      state = AuthState(user: user, isAuthenticated: user != null);
    });
  }

  // Sign-in method
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

  // Sign-out method
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    state = AuthState(user: null, isAuthenticated: false);
  }
}

// Create a provider for the AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
