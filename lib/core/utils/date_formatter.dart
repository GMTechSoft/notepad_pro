import 'package:intl/intl.dart';

class DateFormatter {
  static String getFormattedDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final comparisonDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (comparisonDate == today) {
      return "Today";
    } else if (comparisonDate == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }
}
