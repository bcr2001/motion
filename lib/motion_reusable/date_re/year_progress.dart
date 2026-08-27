class YearProgress {
  const YearProgress._();

  static int daysInYear(int year) {
    return DateTime(year + 1, 1, 1).difference(DateTime(year, 1, 1)).inDays;
  }

  static String formatTrackedDays({
    required int trackedDays,
    required int year,
  }) {
    return '$trackedDays/${daysInYear(year)}';
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
