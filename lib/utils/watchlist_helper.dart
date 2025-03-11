import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/watched_donations_provider.dart';

Future<void> toggleWatchlistStatus(
    BuildContext context,
    String userId,
    String donationId,
    Map<String, bool> watchlistStatus,
    Function setState,
    WidgetRef ref,
    bool mounted,
) async {
  setState(() async {
    if (watchlistStatus[donationId] == true) {
      // Remove from watchlist
      ref.read(watchedDonationsServiceProvider)
        .removeFromWatchlist(userId, donationId)
        .then((_) {
          setState(() {
            watchlistStatus[donationId] = false;
          });
          // Check if the widget is still mounted before showing Snackbar
          if (mounted) {
            showSnackbar(context, "Removed from watchlist", Icons.star_border);
          }
        });
    } else {
      // Add to watchlist
      await ref.read(watchedDonationsServiceProvider)
        .addToWatchlist(userId, donationId, {})
        .then((_) async {
          // Reload the watchlist status after adding
          final status = await ref.read(watchedDonationsServiceProvider)
            .isDonationInWatchlist(userId, donationId);
          
          setState(() {
            watchlistStatus[donationId] = status;
          });

          // Check if the widget is still mounted before showing Snackbar
          if (mounted) {
            showSnackbar(context, "Added to watchlist", Icons.star);
          }
        });
    }
  });
}

void showSnackbar(BuildContext context, String message, IconData icon) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            icon,
            color: Colors.green,
          ),
          SizedBox(width: 8),
          Text(message),
        ],
      ),
      duration: Duration(seconds: 2),
    ),
  );
}
