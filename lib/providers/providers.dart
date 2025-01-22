import 'package:riverpod/riverpod.dart';

// Define the StateProvider for managing the request state
final hasRequestedProvider = StateProvider<bool>((ref) => false);  // Default is false