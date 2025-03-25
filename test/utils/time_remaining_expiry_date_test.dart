import 'package:intl/intl.dart';
import 'package:shelfaware_app/utils/time_remaining_expiry_date.dart';
import 'package:test/test.dart'; // Import the test package

void main() {
  group('getTimeRemaining', () {
    test('should return "Expired" for past date', () {
      // Setup: Choose a date in the past
      String pastDate = '19/03/2025';
      // Act: Call the function
      String result = getTimeRemaining(pastDate);

      // Assert: Check the result
      expect(result, equals('Expired'));
    });

    test('should return "This item expires today" for today\'s date', () {
      // Setup: Choose today's date
      DateTime today = DateTime.now();
      String todayDate = DateFormat('21/03/2025').format(today);

      // Act: Call the function
      String result = getTimeRemaining(todayDate);

      // Assert: Check the result
      expect(result, equals('This item expires today'));
    });

    test('should return "This item expires tomorrow" for expiring tomorrow',
        () {
      // Setup: Choose a date that will expire tomorrow
      DateTime tomorrow = DateTime.now().add(Duration(days: 1));
      String tomorrowDate = DateFormat('22/03/2025').format(tomorrow);

      // Act: Call the function
      String result = getTimeRemaining(tomorrowDate);

      // Assert: Check the result
      expect(result, equals('This item expires tomorrow'));
    });

    test(
        'should return "This item expires in: X days" for dates more than 1 day ahead',
        () {
      // Setup: Choose a date that will expire in more than one day
      DateTime futureDate = DateTime.now().add(Duration(days: 5));
      String futureDateString = DateFormat('24/03/2025').format(futureDate);

      // Act: Call the function
      String result = getTimeRemaining(futureDateString);

      // Assert: Check the result
      expect(result, equals('This item expires in: 3 days'));
    });

    test('should return "Invalid expiry date" for invalid date format', () {
      // Setup: Choose an invalid date format
      String invalidDate = '2025-.03-19';

      // Act: Call the function
      String result = getTimeRemaining(invalidDate);

      // Assert: Check the result
      expect(result, equals('Invalid expiry date'));
    });

    test('should return "Invalid expiry date" for empty date string', () {
      // Setup: Empty string as input
      String emptyDate = '';

      // Act: Call the function
      String result = getTimeRemaining(emptyDate);

      // Assert: Check the result
      expect(result, equals('Invalid expiry date'));
    });
  });
}
