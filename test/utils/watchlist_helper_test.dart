import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mockito/mockito.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shelfaware_app/services/watched_donations_service.dart';
import 'package:shelfaware_app/utils/watchlist_helper.dart';
import 'package:shelfaware_app/providers/watched_donations_provider.dart';

// Mock class for the watchedDonationsServiceProvider
class MockWatchedDonationsService extends Mock
    implements WatchedDonationsService {}

// Mock class for WidgetRef
class MockWidgetRef extends Mock implements WidgetRef {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('toggleWatchlistStatus', () {
    late MockWatchedDonationsService mockWatchedDonationsService;
    late MockWidgetRef mockWidgetRef;

    setUp(() {
      mockWatchedDonationsService = MockWatchedDonationsService();
      mockWidgetRef = MockWidgetRef();

      // Set up the mock behavior for MockWidgetRef.read
      when(() => mockWidgetRef.read(watchedDonationsServiceProvider))
          .thenReturn(mockWatchedDonationsService);
    });

    testWidgets('adds to watchlist and shows snackbar', (tester) async {
      final userId = 'user123';
      final donationId = 'donation123';
      final watchlistStatus = <String, bool>{donationId: false};

      // Initialize the mock service
      when(() => mockWatchedDonationsService
          .addToWatchlist(userId, donationId, {})).thenAnswer((_) async => {});
      when(() => mockWatchedDonationsService.isDonationInWatchlist(
          userId, donationId)).thenAnswer((_) async => true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchedDonationsServiceProvider
                .overrideWithValue(mockWatchedDonationsService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await toggleWatchlistStatus(
                      context,
                      userId,
                      donationId,
                      watchlistStatus,
                      (setState) => setState(),
                      mockWidgetRef,
                      true,
                    );
                  },
                  child: Text('Toggle Watchlist'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger the toggle
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify that the Snackbar is shown with the correct message
      expect(find.text('Added to watchlist'), findsOneWidget);
    });

    testWidgets('removes from watchlist and shows snackbar', (tester) async {
      final userId = 'user123';
      final donationId = 'donation123';
      final watchlistStatus = <String, bool>{donationId: true};

      // Mock the method for removing from watchlist
      when(() => mockWatchedDonationsService.removeFromWatchlist(
          userId, donationId)).thenAnswer((_) async => {});

      when(() => mockWatchedDonationsService.isDonationInWatchlist(
          userId, donationId)).thenAnswer((_) async => false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchedDonationsServiceProvider
                .overrideWithValue(mockWatchedDonationsService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await toggleWatchlistStatus(
                      context,
                      userId,
                      donationId,
                      watchlistStatus,
                      (setState) => setState(),
                      mockWidgetRef,
                      true,
                    );
                  },
                  child: Text('Toggle Watchlist'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger the toggle
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify that the Snackbar is shown with the correct message
      expect(find.text('Removed from watchlist'), findsOneWidget);
    });
  });
}
