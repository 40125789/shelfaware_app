import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/services/auth_services.dart';
import 'package:shelfaware_app/services/donation_service.dart';


// Define the authStateProvider
final authStateProvider = StreamProvider<User?>((ref) {
  // Replace with your actual implementation to get the auth state
  return AuthService().authStateChanges;  
});

// Create a provider for DonationService (or repository)
final donationServiceProvider = Provider((ref) => DonationService());

// Provider for fetching user donations
final userDonationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider); // Watch the auth state provider
  final donationService = ref.watch(donationServiceProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return donationService.getDonations(user.uid);
      } else {
        return Stream.value([]); // Return an empty stream if the user is not authenticated
      }
    },
    loading: () => Stream.value([]), // Return an empty stream while loading
    error: (_, __) => Stream.value([]), // Return an empty stream on error
  );
});

// Provider for fetching sent donation requests
final sentRequestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider); // Watch the auth state provider
  final donationService = ref.watch(donationServiceProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return donationService.getSentDonationRequests(user.uid);
      } else {
        return Stream.value([]); // Return an empty stream if the user is not authenticated
      }
    },
    loading: () => Stream.value([]), // Return an empty stream while loading
    error: (_, __) => Stream.value([]), // Return an empty stream on error
  );
});

// Provider for fetching donation request count (caching is useful for performance)
final donationRequestCountProvider = StreamProvider.family<int, String>((ref, donationId) {
  final donationService = ref.watch(donationServiceProvider);
  return donationService.getDonationRequestCount(donationId);
});
