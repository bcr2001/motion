const double _rankComparisonTolerance = 0.0001;

List<Map<String, dynamic>> applySubcategoryRankMovement({
  required List<Map<String, dynamic>> rankedItems,
  required Map<String, double> comparisonPeriodTotals,
}) {
  final items = rankedItems
      .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
      .toList(growable: true);

  double totalOf(Map<String, dynamic> item) =>
      (item['total'] as num?)?.toDouble() ?? 0;
  String nameOf(Map<String, dynamic> item) =>
      item['subcategoryName'].toString();

  final previousTotals = <String, double>{
    for (final item in items)
      nameOf(item): totalOf(item) - (comparisonPeriodTotals[nameOf(item)] ?? 0),
  };

  int compareTotals(double first, double second) {
    if ((first - second).abs() <= _rankComparisonTolerance) return 0;
    return second.compareTo(first);
  }

  final previouslyRanked = items
      .where(
        (item) =>
            (previousTotals[nameOf(item)] ?? 0) > _rankComparisonTolerance,
      )
      .toList(growable: false)
    ..sort((first, second) {
      final totalComparison = compareTotals(
        previousTotals[nameOf(first)] ?? 0,
        previousTotals[nameOf(second)] ?? 0,
      );
      if (totalComparison != 0) return totalComparison;
      return nameOf(first).compareTo(nameOf(second));
    });

  final previousRanks = <String, int>{
    for (var index = 0; index < previouslyRanked.length; index++)
      nameOf(previouslyRanked[index]): index + 1,
  };

  items.sort((first, second) {
    final totalComparison = compareTotals(totalOf(first), totalOf(second));
    if (totalComparison != 0) return totalComparison;

    // Keeping the old order for ties prevents a category from appearing to
    // move up before it has actually overtaken the category above it.
    final firstPreviousRank = previousRanks[nameOf(first)];
    final secondPreviousRank = previousRanks[nameOf(second)];
    if (firstPreviousRank != null && secondPreviousRank != null) {
      return firstPreviousRank.compareTo(secondPreviousRank);
    }
    if (firstPreviousRank != null) return -1;
    if (secondPreviousRank != null) return 1;
    return nameOf(first).compareTo(nameOf(second));
  });

  return [
    for (var index = 0; index < items.length; index++)
      () {
        final item = items[index];
        final name = nameOf(item);
        final currentRank = index + 1;
        final previousRank = previousRanks[name];
        final isNewRank = previousRank == null &&
            (comparisonPeriodTotals[name] ?? 0) > _rankComparisonTolerance;

        return <String, dynamic>{
          ...item,
          'currentRank': currentRank,
          'previousRank': previousRank,
          'rankMovement': previousRank == null ? 0 : previousRank - currentRank,
          'isNewRank': isNewRank,
        };
      }(),
  ];
}
