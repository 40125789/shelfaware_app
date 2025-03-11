import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/utils/date_utils.dart';

void main() {
  group('DateUtils', () {
    test('getFormattedDate returns "Today" for today\'s date', () {
      final today = DateTime.now();
      final result = DateUtils.getFormattedDate(today);
      expect(result, "Today");
    });

    test('getFormattedDate returns "Yesterday" for yesterday\'s date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = DateUtils.getFormattedDate(yesterday);
      expect(result, "Yesterday");
    });

    test('getFormattedDate returns formatted date for other dates', () {
      final date = DateTime(2023, 10, 1);
      final result = DateUtils.getFormattedDate(date);
      expect(result, "1st October 2023");
    });

    test('isSameDay returns true for the same day', () {
      final date1 = DateTime(2023, 10, 1);
      final date2 = DateTime(2023, 10, 1);
      final result = DateUtils.isSameDay(date1, date2);
      expect(result, true);
    });

    test('isSameDay returns false for different days', () {
      final date1 = DateTime(2023, 10, 1);
      final date2 = DateTime(2023, 10, 2);
      final result = DateUtils.isSameDay(date1, date2);
      expect(result, false);
    });

    test('getDaySuffix returns correct suffix for 1', () {
      final result = DateUtils.getDaySuffix(1);
      expect(result, 'st');
    });

    test('getDaySuffix returns correct suffix for 2', () {
      final result = DateUtils.getDaySuffix(2);
      expect(result, 'nd');
    });

    test('getDaySuffix returns correct suffix for 3', () {
      final result = DateUtils.getDaySuffix(3);
      expect(result, 'rd');
    });

    test('getDaySuffix returns correct suffix for 4', () {
      final result = DateUtils.getDaySuffix(4);
      expect(result, 'th');
    });

    test('getDaySuffix returns correct suffix for 11', () {
      final result = DateUtils.getDaySuffix(11);
      expect(result, 'th');
    });

    test('getDaySuffix returns correct suffix for 21', () {
      final result = DateUtils.getDaySuffix(21);
      expect(result, 'st');
    });
  });
}
