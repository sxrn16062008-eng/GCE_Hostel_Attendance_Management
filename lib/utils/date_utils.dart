import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _storageFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayFormat = DateFormat('EEEE, dd MMMM yyyy');
  static final DateFormat _shortDisplayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  /// Formats a DateTime to standardized storage key (e.g. "2026-09-08")
  static String formatForStorage(DateTime date) {
    return _storageFormat.format(date);
  }

  /// Parses standardized storage key (e.g. "2026-09-08") back to DateTime
  static DateTime parseStorage(String dateString) {
    try {
      return _storageFormat.parse(dateString);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Returns full human readable string (e.g. "Tuesday, 08 September 2026")
  static String formatDisplay(DateTime date) {
    return _displayFormat.format(date);
  }

  /// Returns short readable string (e.g. "08 Sep 2026")
  static String formatShort(DateTime date) {
    return _shortDisplayFormat.format(date);
  }

  /// Returns formatted time (e.g. "08:30 PM")
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  /// Formats a DateTime to date and time (e.g. "08 Sep 2026, 08:30 PM")
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Returns today's storage formatted string
  static String todayStorage() {
    return formatForStorage(DateTime.now());
  }



  /// Returns today's human-readable display string
  static String todayDisplay() {
    return formatDisplay(DateTime.now());
  }

  /// Checks if given date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

// Alias for convenience
typedef DateUtils = AppDateUtils;

