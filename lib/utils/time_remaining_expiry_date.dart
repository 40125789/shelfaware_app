import 'package:intl/intl.dart';

String getTimeRemaining(String expiryDateStr) {
  try {
    // Use DateFormat to parse the expiry date
    DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    DateTime expiryDate = dateFormat.parse(expiryDateStr);

    // Get today's date without time (00:00:00)
    DateTime today = DateTime.now();
    DateTime todayWithoutTime = DateTime(today.year, today.month, today.day);

    // Check if expired
    if (expiryDate.isBefore(todayWithoutTime)) {
      return 'Expired';
    }

    // Calculate days remaining
    int daysRemaining = expiryDate.difference(todayWithoutTime).inDays;

    if (daysRemaining == 0) {
      return 'This item expires today';
    } else if (daysRemaining == 1) {
      return 'This item expires tomorrow';
    } else {
      return 'This item expires in: $daysRemaining days';
    }
  } catch (e) {
    return 'Invalid expiry date'; // Handles parsing errors
  }
}
