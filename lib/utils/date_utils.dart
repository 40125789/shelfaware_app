import 'package:intl/intl.dart';

class DateUtils {
  static String getFormattedDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (isSameDay(today, date)) {
      return "Today";
    } else if (isSameDay(yesterday, date)) {
      return "Yesterday";
    } else {
      final daySuffix = getDaySuffix(date.day);
      return DateFormat("d'$daySuffix' MMMM yyyy").format(date);
    }
  }

  static bool isSameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year && day1.month == day2.month && day1.day == day2.day;
  }

  static String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}