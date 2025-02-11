import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationNotifier extends StateNotifier<LatLng?> {
  StreamSubscription? _subscription;

  LocationNotifier() : super(null) {
    _subscribeToUserLocation();
  }

  void _subscribeToUserLocation() {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots() // LISTEN FOR CHANGES
        .listen((userDoc) {
      if (userDoc.exists) {
        GeoPoint geoPoint = userDoc['location'];
        print("📍 Location Updated: ${geoPoint.latitude}, ${geoPoint.longitude}");
        state = LatLng(geoPoint.latitude, geoPoint.longitude);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel(); // STOP LISTENING WHEN NOTIFIER IS DISPOSED
    super.dispose();
  }

  void updateLocation(LatLng newLocation) {
    state = newLocation;
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LatLng?>((ref) {
  return LocationNotifier();
});