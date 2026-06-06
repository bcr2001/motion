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

    return SqlDateRange._(
      startDate: '$parsedYear-01-01',
      endDate: '$parsedYear-12-31',
    );
  }

  List<String> get args => [startDate, endDate];
}
