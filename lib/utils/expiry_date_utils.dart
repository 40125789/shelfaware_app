import 'package:cloud_firestore/cloud_firestore.dart';

class ExpiryDateUtils {
  static String formatExpiryDate(Timestamp expiryTimestamp) {
    DateTime expiryDate = expiryTimestamp.toDate();
    DateTime today = DateTime.now();
    int daysDifference = expiryDate.difference(today).inDays;

    // Determine the expiry date message
    if (daysDifference < 0) {
      return 'Expired'; // If expired, show 'Expired'
    } else if (daysDifference == 0) {
      return 'Expires today'; // If it expires today
    } else if (daysDifference <= 4) {
      return 'Expires in: $daysDifference day${daysDifference == 1 ? '' : 's'}'; // Expiring soon
    } else {
      return 'Expires in: $daysDifference day${daysDifference == 1 ? '' : 's'}'; // Fresh items
    }
  }

  static String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }
}
