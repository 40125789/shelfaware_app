import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
      if (user != null) {
        // Call listenForTokenRefresh when user is authenticated
        listenForTokenRefresh();
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await storeFCMToken(user.uid, fcmToken); // Store FCM token
        }
      }

      state = AuthState(user: user, isAuthenticated: true);
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      User? user = _firebaseAuth.currentUser;
    

      await _firebaseAuth.signOut();
      state = AuthState(user: null, isAuthenticated: false);
    } catch (e) {
      print("Error during sign-out: $e");
    }
  }

  void listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await storeFCMToken(user.uid, newToken);
        print("FCM Token refreshed and updated: $newToken");
      }
    });
  }

  Future<void> storeFCMToken(String userId, String token) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.set({'fcm_token': token}, SetOptions(merge: true));
      print("FCM token stored: $token for user: $userId");
    } catch (e) {
      print("Error storing FCM token: $e");
    }
  }



  @override
  void dispose() {
    _authSubscription?.cancel(); // Cancel the listener when no longer needed
    super.dispose();
  }
}
