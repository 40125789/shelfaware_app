import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/utils/time_remaining_expiry_date.dart';

void main() {
  group('getTimeRemaining', () {
    test('returns "Invalid expiry date" for invalid date format', () {
      expect(getTimeRemaining('invalid-date'), 'Invalid expiry date');
    });

    test('returns "Expired" for past date', () {
      final pastDate = DateTime.now().subtract(Duration(days: 1));
      final formattedPastDate = '${pastDate.day}/${pastDate.month}/${pastDate.year}';
      expect(getTimeRemaining(formattedPastDate), 'Expired');
    });

    test('returns "This item expires in less than a day" for date within 24 hours', () {
      final futureDate = DateTime.now().add(Duration(hours: 23));
      final formattedFutureDate = '${futureDate.day}/${futureDate.month}/${futureDate.year}';
      expect(getTimeRemaining(formattedFutureDate), 'This item expires in less than a day');
    });

    test('returns "This item expires tomorrow" for date exactly 1 day in the future', () {
      final futureDate = DateTime.now().add(Duration(days: 1));
      final formattedFutureDate = '${futureDate.day}/${futureDate.month}/${futureDate.year}';
      expect(getTimeRemaining(formattedFutureDate), 'This item expires tomorrow');
    });

    test('returns correct days remaining for future date', () {
      final futureDate = DateTime.now().add(Duration(days: 5));
      final formattedFutureDate = '${futureDate.day}/${futureDate.month}/${futureDate.year}';
      expect(getTimeRemaining(formattedFutureDate), 'This item expires in: 5 days');
    });
  });
}