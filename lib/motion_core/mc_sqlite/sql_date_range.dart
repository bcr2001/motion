import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

class SqlDateRange {
  final String startDate;
  final String endDate;

  const SqlDateRange._({
    required this.startDate,
    required this.endDate,
  });

  factory SqlDateRange.year(String year) {
    final parsedYear = int.tryParse(year);
    if (parsedYear == null) {
      throw FormatException('Invalid year for SQL date range: $year');
    }

    final range = MotionDateUtils.yearRange(parsedYear);
    return SqlDateRange._(startDate: range.startIso, endDate: range.endIso);
  }

  List<String> get args => [startDate, endDate];
}
