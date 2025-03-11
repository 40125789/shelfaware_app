import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/utils/expiry_date_utils.dart';

void main() {
  group('ExpiryDateUtils', () {
    test('formatExpiryDate returns "Expired" for past dates', () {
      Timestamp pastTimestamp =
          Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1)));
      expect(ExpiryDateUtils.formatExpiryDate(pastTimestamp), 'Expired');
    });

    test('formatExpiryDate returns "Expires today" for today\'s date', () {
      Timestamp todayTimestamp = Timestamp.fromDate(DateTime.now());
      expect(ExpiryDateUtils.formatExpiryDate(todayTimestamp), 'Expires today');
    });

    test(
        'formatExpiryDate returns "Expires in: X days" for dates within 4 days',
        () {
      Timestamp futureTimestamp =
          Timestamp.fromDate(DateTime.now().add(Duration(days: 3)));
      expect(ExpiryDateUtils.formatExpiryDate(futureTimestamp),
          'Expires in: 3 days');
    });

    test(
        'formatExpiryDate returns "Expires in: X days" for dates beyond 4 days',
        () {
      Timestamp futureTimestamp =
          Timestamp.fromDate(DateTime.now().add(Duration(days: 5)));
      expect(ExpiryDateUtils.formatExpiryDate(futureTimestamp),
          'Expires in: 5 days');
    });

    test('formatDate returns formatted date string', () {
      DateTime date = DateTime(2023, 10, 5, 14, 30);
      Timestamp timestamp = Timestamp.fromDate(date);
      expect(ExpiryDateUtils.formatDate(timestamp), '5/10/2023 14:30');
    });
  });
}
