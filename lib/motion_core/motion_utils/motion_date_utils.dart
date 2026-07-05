import 'package:intl/intl.dart';

class MotionDateRange {
  const MotionDateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  String get startIso => MotionDateUtils.formatDbDate(start);
  String get endIso => MotionDateUtils.formatDbDate(end);
  List<String> get sqlArgs => [startIso, endIso];
}

class MotionDateUtils {
  MotionDateUtils._();

  static const storedDatePattern = 'yyyy-MM-dd';

  static final DateFormat _storedDateFormatter =
      DateFormat(storedDatePattern);
  static final DateFormat _displayDateFormatter =
      DateFormat('EEE, MMM d, yyyy');
  static final DateFormat _longDisplayDateFormatter =
      DateFormat('dd MMMM yyyy');
  static final DateFormat _weekdayFormatter = DateFormat('EEEE');

  static DateTime today({DateTime Function()? now}) {
    return dateOnly((now ?? DateTime.now)());
  }

  static String todayIso({DateTime Function()? now}) {
    return formatDbDate(today(now: now));
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDate(DateTime first, DateTime second) {
    return dateOnly(first) == dateOnly(second);
  }

  static String formatDbDate(DateTime date) {
    return _storedDateFormatter.format(dateOnly(date));
  }

  static String formatDisplayDate(DateTime date) {
    return _displayDateFormatter.format(dateOnly(date));
  }

  static String formatLongDisplayDate(DateTime date) {
    return _longDisplayDateFormatter.format(dateOnly(date));
  }

  static String formatWeekdayOrdinal(DateTime date) {
    final normalized = dateOnly(date);
    final day = normalized.day;
    return '${_weekdayFormatter.format(normalized)} $day${daySuffix(day)} ';
  }

  static String daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    return switch (day % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
  }

  static DateTime? parseStoredDate(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;

    final isoDate = DateTime.tryParse(text);
    if (isoDate != null) return dateOnly(isoDate);

    for (final pattern in ['M/d/yyyy', 'd/M/yyyy']) {
      try {
        return dateOnly(DateFormat(pattern).parseStrict(text));
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static String normalizeStoredDate(Object? value) {
    final parsed = parseStoredDate(value);
    return parsed == null ? '' : formatDbDate(parsed);
  }

  static MotionDateRange monthRange(DateTime date) {
    final normalized = dateOnly(date);
    return MotionDateRange(
      start: DateTime(normalized.year, normalized.month, 1),
      end: DateTime(normalized.year, normalized.month + 1, 0),
    );
  }

  static MotionDateRange weekRange(DateTime date) {
    final normalized = dateOnly(date);
    final start = normalized.subtract(Duration(days: normalized.weekday - 1));
    return MotionDateRange(
      start: start,
      end: start.add(const Duration(days: 6)),
    );
  }

  static MotionDateRange yearRange(int year) {
    return MotionDateRange(
      start: DateTime(year, 1, 1),
      end: DateTime(year, 12, 31),
    );
  }

  static int inclusiveDaysBetween(DateTime startDate, DateTime endDate) {
    final start = dateOnly(startDate);
    final end = dateOnly(endDate);
    if (end.isBefore(start)) return 0;
    return end.difference(start).inDays + 1;
  }

  static DateTime minDate(DateTime first, DateTime second) {
    final firstDate = dateOnly(first);
    final secondDate = dateOnly(second);
    return firstDate.isBefore(secondDate) ? firstDate : secondDate;
  }
}
