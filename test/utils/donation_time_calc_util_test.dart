import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/utils/donation_time_calc_util.dart';

void main() {
  group('calculateTimeAgo', () {
    test('returns "Just now" for less than a minute', () {
      final now = DateTime.now();
      final result = calculateTimeAgo(now.subtract(Duration(seconds: 30)));
      expect(result, 'Just now');
    });

    test('returns minutes ago for less than an hour', () {
      final now = DateTime.now();
      final result = calculateTimeAgo(now.subtract(Duration(minutes: 45)));
      expect(result, '45 minutes ago');
    });

    test('returns hours ago for less than a day', () {
      final now = DateTime.now();
      final result = calculateTimeAgo(now.subtract(Duration(hours: 5)));
      expect(result, '5 hours ago');
    });

    test('returns days ago for more than a day', () {
      final now = DateTime.now();
      final result = calculateTimeAgo(now.subtract(Duration(days: 3)));
      expect(result, '3 days ago');
    });
  });
}
