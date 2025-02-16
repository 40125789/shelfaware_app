import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/repositories/watched_donations_repository.dart';
import 'package:shelfaware_app/services/watched_donations_service.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';




final watchedDonationsRepositoryProvider = Provider<WatchedDonationsRepository>((ref) {
  return WatchedDonationsRepository();
});

final watchedDonationsServiceProvider = Provider<WatchedDonationsService>((ref) {
  final watchedDonationsRepository = ref.watch(watchedDonationsRepositoryProvider);
  return WatchedDonationsService(watchedDonationsRepository);
});

final watchedDonationsStreamProvider = StreamProvider.autoDispose((ref) {
  final watchedDonationsService = ref.watch(watchedDonationsServiceProvider);
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return watchedDonationsService.getWatchedDonations(user.uid);
      } else {
        return Stream.empty(); // Return an empty stream if the user is not authenticated
      }
    },
    loading: () => Stream.empty(), // Return an empty stream while loading
    error: (_, __) => Stream.empty(), // Return an empty stream on error
  );
});