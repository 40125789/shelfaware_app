import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomNavController extends StateNotifier<int> {
  BottomNavController() : super(0); // Initial selected index is 0

  // Method to change the selected index
  void navigateTo(int index) {
    state = index;  // Update the state
  }
}

// Create a StateNotifierProvider for BottomNavController
final bottomNavControllerProvider = StateNotifierProvider<BottomNavController, int>((ref) {
  return BottomNavController();
});