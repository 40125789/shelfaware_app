import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/utils/donation_filter_calc_util.dart';

void main() {
  group('isNewlyAdded', () {
    test('returns false when addedOn is null', () {
      expect(isNewlyAdded(null), false);
    });

    test('returns true when addedOn is within the last 24 hours', () {
      var now = DateTime.now();
      var timestamp = Timestamp.fromDate(now.subtract(Duration(hours: 23)));
      expect(isNewlyAdded(timestamp), true);
    });

    test('returns false when addedOn is more than 24 hours ago', () {
      var now = DateTime.now();
      var timestamp = Timestamp.fromDate(now.subtract(Duration(hours: 25)));
      expect(isNewlyAdded(timestamp), false);
    });
  });

  group('isExpiringSoon', () {
    test('returns false when expiryDate is null', () {
      expect(isExpiringSoon(null), false);
    });

    test('returns true when expiryDate is within the next 3 days', () {
      var now = DateTime.now();
      var timestamp = Timestamp.fromDate(now.add(Duration(days: 2)));
      expect(isExpiringSoon(timestamp), true);
    });

    test('returns false when expiryDate is more than 3 days away', () {
      var now = DateTime.now();
      var timestamp = Timestamp.fromDate(now.add(Duration(days: 4)));
      expect(isExpiringSoon(timestamp), false);
    });

    test('returns false when expiryDate is in the past', () {
      var now = DateTime.now();
      var timestamp = Timestamp.fromDate(now.subtract(Duration(days: 1)));
      expect(isExpiringSoon(timestamp), false);
    });
  });
}
