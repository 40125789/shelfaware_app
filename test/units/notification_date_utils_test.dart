import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/utils/notification_date_utils.dart';

void main() {
  group('NotificationDateUtils', () {
    test('should return minutes ago if difference is less than 60 minutes', () {
      Timestamp timestamp = Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 30)));
      String result = NotificationDateUtils.formatTimestamp(timestamp);
      expect(result, '30 minutes ago');
    });

    test('should return hours ago if difference is less than 24 hours', () {
      Timestamp timestamp = Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 5)));
      String result = NotificationDateUtils.formatTimestamp(timestamp);
      expect(result, '5 hours ago');
    });

    test('should return days ago if difference is more than 24 hours', () {
      Timestamp timestamp = Timestamp.fromDate(DateTime.now().subtract(Duration(days: 2)));
      String result = NotificationDateUtils.formatTimestamp(timestamp);
      expect(result, '2 days ago');
    });
  });
}