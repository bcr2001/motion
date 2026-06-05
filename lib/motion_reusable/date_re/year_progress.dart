class YearProgress {
  const YearProgress._();

  static int daysInYear(int year) {
    return DateTime(year + 1, 1, 1).difference(DateTime(year, 1, 1)).inDays;
  }

  static double percentComplete({
    required int elapsedDays,
    required int year,
  }) {
    final totalDays = daysInYear(year);
    final boundedElapsedDays = elapsedDays < 0
        ? 0
        : elapsedDays > totalDays
            ? totalDays
            : elapsedDays;

    return (boundedElapsedDays / totalDays) * 100;
  }
}
