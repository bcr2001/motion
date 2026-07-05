part of 'streak_detail_page.dart';

class BestStreaksSection extends StatelessWidget {
  final SubcategoryStreakStatus streak;
  final Color borderColor;

  const BestStreaksSection({
    super.key,
    required this.streak,
    required this.borderColor,
  });

  String _formatDisplayDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  List<SubcategoryBestStreakRun> _centerBestRun(
    List<SubcategoryBestStreakRun> runs,
  ) {
    if (runs.length <= 2) return runs;

    final maxStreak = runs.fold<int>(
      0,
      (maxValue, run) => math.max(maxValue, run.streakLength),
    );
    final bestIndex = runs.indexWhere((run) => run.streakLength == maxStreak);
    final bestRun = runs[bestIndex];
    final otherRuns = [...runs]..removeAt(bestIndex);

    otherRuns.sort((a, b) => b.endDate.compareTo(a.endDate));

    final aboveCount = otherRuns.length ~/ 2;
    return [
      ...otherRuns.take(aboveCount),
      bestRun,
      ...otherRuns.skip(aboveCount),
    ];
  }

  Widget _streakRunRow({
    required SubcategoryBestStreakRun run,
    required int maxStreak,
    required bool isBest,
    required bool isDarkMode,
  }) {
    final factor = maxStreak <= 0
        ? 0.0
        : (run.streakLength / maxStreak).clamp(0.14, 1.0).toDouble();
    final accentColor = isBest
        ? AppColor.accountedColor
        : run.streakLength >= (maxStreak * 0.55)
            ? AppColor.accountedColor.withValues(alpha: 0.64)
            : Colors.blueGrey.withValues(alpha: isDarkMode ? 0.35 : 0.22);
    final textColor = isBest
        ? (isDarkMode ? Colors.black : Colors.black87)
        : (isDarkMode ? Colors.white70 : Colors.blueGrey.shade700);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isBest ? 5 : 3),
      child: Row(
        children: [
          Expanded(
            flex: 31,
            child: Text(
              _formatDisplayDate(run.startDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 10.5,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 38,
            child: Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: factor,
                child: Container(
                  height: isBest ? 25 : 21,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isBest
                        ? [
                            BoxShadow(
                              color: AppColor.accountedColor
                                  .withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    run.streakLength.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: isBest ? 12.5 : 11,
                      fontweight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 31,
            child: Text(
              _formatDisplayDate(run.endDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 10.5,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    const accentColor = AppColor.accountedColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: accentColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Streaks',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 15,
                        fontweight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Top runs across all years',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 11,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  'All time',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer2<UserUidProvider, CurrentDateProvider>(
            builder: (context, user, date, child) {
              final currentUser = user.userUid;
              if (currentUser == null) {
                return const SizedBox(
                  height: 148,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tracker = context.read<MainCategoryTrackerProvider>();
              return FutureBuilder<List<SubcategoryBestStreakRun>>(
                future: tracker.retrieveSubcategoryBestStreakRuns(
                  currentUser: currentUser,
                  subcategoryName: streak.subcategoryName,
                  mainCategoryName: streak.mainCategoryName,
                  streakType: streak.streakType,
                  targetMinutes: streak.targetMinutes,
                  startDate: streak.startDate,
                  currentDate: date.currentDate,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 148,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 148,
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  }

                  final runs = snapshot.data ?? [];
                  if (runs.isEmpty) {
                    return SizedBox(
                      height: 148,
                      child: Center(
                        child: Text(
                          'No completed streaks yet',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 13,
                            fontweight: FontWeight.normal,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    );
                  }

                  final displayRuns = _centerBestRun(runs);
                  final maxStreak = runs.fold<int>(
                    0,
                    (maxValue, run) =>
                        math.max(maxValue, run.streakLength),
                  );

                  return Column(
                    children: [
                      for (final run in displayRuns)
                        _streakRunRow(
                          run: run,
                          maxStreak: maxStreak,
                          isBest: run.streakLength == maxStreak,
                          isDarkMode: isDarkMode,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
