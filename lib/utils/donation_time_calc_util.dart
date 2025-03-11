import 'package:intl/intl.dart';

String calculateTimeAgo(DateTime donationTime) {
  final now = DateTime.now();
  final timeDiff = now.difference(donationTime);
  String timeAgo;
if (timeDiff.inMinutes < 1) {
  timeAgo = 'Just now'; // Less than a minute
} else if (timeDiff.inMinutes < 60) {
  timeAgo = '${timeDiff.inMinutes} minutes ago'; // Less than an hour
} else if (timeDiff.inHours < 24) {
  timeAgo = '${timeDiff.inHours} hours ago'; // Less than a day
} else {
  timeAgo = '${timeDiff.inDays} days ago'; // More than a day
}
  return timeAgo;
}

