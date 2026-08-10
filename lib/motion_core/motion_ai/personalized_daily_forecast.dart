import 'dart:math' as math;

import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/mc_sqlite/xp_policy.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

enum DailyForecastStatus {
  learning,
  noTarget,
  atRisk,
  withinReach,
  onTrack,
  targetAchieved,
}

class DailyForecastFocus {
  const DailyForecastFocus({
    required this.category,
    required this.earnedXp,
    required this.suggestedXp,
    required this.historicalAverageXp,
    required this.trackedMinutes,
    required this.targetMinutes,
  });

  final String category;
  final int earnedXp;
  final int suggestedXp;
  final double historicalAverageXp;
  final int trackedMinutes;
  final int targetMinutes;

  int get remainingXp => math.max(0, suggestedXp - earnedXp);
  int get remainingMinutes => math.max(0, targetMinutes - trackedMinutes);
  double get progress => suggestedXp <= 0
      ? 0
      : (earnedXp / suggestedXp).clamp(0.0, 1.0).toDouble();
}

class DailyForecastNextMove {
  const DailyForecastNextMove({
    required this.category,
    required this.xpToEarn,
    required this.minutesRequired,
  });

  final String category;
  final int xpToEarn;
  final int minutesRequired;
}

class PersonalizedDailyForecast {
  const PersonalizedDailyForecast({
    required this.date,
    required this.earnedXp,
    required this.targetXp,
    required this.predictedXp,
    required this.lowerXp,
    required this.upperXp,
    required this.targetProbability,
    required this.status,
    required this.historyDays,
    required this.trackedHistoryDays,
    required this.focus,
    required this.bestNextMove,
    required this.factors,
    required this.hasEnoughHistory,
  });

  final DateTime date;
  final int earnedXp;
  final int targetXp;
  final double predictedXp;
  final int lowerXp;
  final int upperXp;
  final double? targetProbability;
  final DailyForecastStatus status;
  final int historyDays;
  final int trackedHistoryDays;
  final List<DailyForecastFocus> focus;
  final DailyForecastNextMove? bestNextMove;
  final List<String> factors;
  final bool hasEnoughHistory;

  int get predictedXpRounded => predictedXp.round();
  bool get hasTarget => targetXp > 0;
}

class DailyForecastAttentionSnapshot {
  const DailyForecastAttentionSnapshot({
    required this.date,
    required this.predictedXp,
    this.lowerXp = 0,
    this.upperXp = 0,
    required this.targetXp,
    required this.targetProbability,
    required this.status,
    required this.primaryFocus,
  });

  factory DailyForecastAttentionSnapshot.fromForecast(
    PersonalizedDailyForecast forecast,
  ) {
    return DailyForecastAttentionSnapshot(
      date: MotionDateUtils.formatDbDate(forecast.date),
      predictedXp: forecast.predictedXpRounded,
      lowerXp: forecast.lowerXp,
      upperXp: forecast.upperXp,
      targetXp: forecast.targetXp,
      targetProbability: forecast.targetProbability,
      status: forecast.status,
      primaryFocus: forecast.bestNextMove?.category ??
          (forecast.focus.isEmpty ? null : forecast.focus.first.category),
    );
  }

  factory DailyForecastAttentionSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    final statusName = json['status']?.toString();
    final status = DailyForecastStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => DailyForecastStatus.learning,
    );
    final probability = json['targetProbability'];

    final predictedXp = (json['predictedXp'] as num?)?.round() ?? 0;
    return DailyForecastAttentionSnapshot(
      date: json['date']?.toString() ?? '',
      predictedXp: predictedXp,
      lowerXp: (json['lowerXp'] as num?)?.round() ?? predictedXp,
      upperXp: (json['upperXp'] as num?)?.round() ?? predictedXp,
      targetXp: (json['targetXp'] as num?)?.round() ?? 0,
      targetProbability: (probability as num?)?.toDouble(),
      status: status,
      primaryFocus: json['primaryFocus']?.toString(),
    );
  }

  final String date;
  final int predictedXp;
  final int lowerXp;
  final int upperXp;
  final int targetXp;
  final double? targetProbability;
  final DailyForecastStatus status;
  final String? primaryFocus;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'predictedXp': predictedXp,
      'lowerXp': lowerXp,
      'upperXp': upperXp,
      'targetXp': targetXp,
      'targetProbability': targetProbability,
      'status': status.name,
      'primaryFocus': primaryFocus,
    };
  }

  int get displayLowerXp =>
      lowerXp == 0 && upperXp == 0 ? predictedXp : lowerXp;
  int get displayUpperXp =>
      lowerXp == 0 && upperXp == 0 ? predictedXp : upperXp;
}

enum DailyForecastChangeTone { neutral, positive, attention }

class DailyForecastChange {
  const DailyForecastChange({
    required this.title,
    required this.details,
    required this.tone,
  });

  final String title;
  final List<String> details;
  final DailyForecastChangeTone tone;

  static DailyForecastChange? between({
    required DailyForecastAttentionSnapshot? lastSeen,
    required DailyForecastAttentionSnapshot current,
  }) {
    if (!DailyForecastAttentionPolicy.hasMeaningfulChange(
      lastSeen: lastSeen,
      current: current,
    )) {
      return null;
    }
    if (lastSeen == null || lastSeen.date != current.date) {
      final details = <String>[
        'Expected range: ${current.displayLowerXp}-${current.displayUpperXp} XP.',
      ];
      if (current.targetProbability != null) {
        details.add(
          'Target likelihood: ${(current.targetProbability! * 100).round()}%.',
        );
      }
      return DailyForecastChange(
        title: lastSeen == null
            ? 'New forecast ready'
            : "Today's forecast is ready",
        details: details,
        tone: DailyForecastChangeTone.neutral,
      );
    }

    final details = <String>[];
    var positiveSignals = 0;
    var attentionSignals = 0;
    final predictionDelta = current.predictedXp - lastSeen.predictedXp;
    if (predictionDelta.abs() >= 5) {
      details.add(
        'Expected XP changed from '
        '${lastSeen.displayLowerXp}-${lastSeen.displayUpperXp} to '
        '${current.displayLowerXp}-${current.displayUpperXp}.',
      );
      if (predictionDelta > 0) {
        positiveSignals++;
      } else {
        attentionSignals++;
      }
    }

    final previousProbability = lastSeen.targetProbability;
    final currentProbability = current.targetProbability;
    if (previousProbability != null &&
        currentProbability != null &&
        (currentProbability - previousProbability).abs() >= 0.10) {
      details.add(
        'Target likelihood changed from '
        '${(previousProbability * 100).round()}% to '
        '${(currentProbability * 100).round()}%.',
      );
      if (currentProbability > previousProbability) {
        positiveSignals++;
      } else {
        attentionSignals++;
      }
    }

    if (lastSeen.status != current.status) {
      details.add(
        'Status changed from ${_statusLabel(lastSeen.status)} to '
        '${_statusLabel(current.status)}.',
      );
      final statusDelta =
          _statusRank(current.status) - _statusRank(lastSeen.status);
      if (statusDelta > 0) {
        positiveSignals++;
      } else if (statusDelta < 0) {
        attentionSignals++;
      }
    }

    if (lastSeen.primaryFocus != current.primaryFocus &&
        current.primaryFocus != null) {
      details.add('Recommended focus changed to ${current.primaryFocus}.');
    }
    if ((lastSeen.targetXp - current.targetXp).abs() >= 5) {
      details.add(
        'Daily target changed from ${lastSeen.targetXp} to '
        '${current.targetXp} XP.',
      );
    }

    final tone = positiveSignals > attentionSignals
        ? DailyForecastChangeTone.positive
        : attentionSignals > positiveSignals
            ? DailyForecastChangeTone.attention
            : DailyForecastChangeTone.neutral;
    return DailyForecastChange(
      title: switch (tone) {
        DailyForecastChangeTone.positive => 'Your outlook improved',
        DailyForecastChangeTone.attention => 'Your outlook needs attention',
        DailyForecastChangeTone.neutral => 'Your forecast changed',
      },
      details: details.isEmpty
          ? const ['Your recommended plan has been updated.']
          : details,
      tone: tone,
    );
  }

  static int _statusRank(DailyForecastStatus status) {
    return switch (status) {
      DailyForecastStatus.learning => 0,
      DailyForecastStatus.noTarget => 0,
      DailyForecastStatus.atRisk => 1,
      DailyForecastStatus.withinReach => 2,
      DailyForecastStatus.onTrack => 3,
      DailyForecastStatus.targetAchieved => 4,
    };
  }

  static String _statusLabel(DailyForecastStatus status) {
    return switch (status) {
      DailyForecastStatus.learning => 'Learning',
      DailyForecastStatus.noTarget => 'Forecast Only',
      DailyForecastStatus.atRisk => 'At Risk',
      DailyForecastStatus.withinReach => 'Within Reach',
      DailyForecastStatus.onTrack => 'On Track',
      DailyForecastStatus.targetAchieved => 'Target Achieved',
    };
  }
}

class DailyForecastAttentionPolicy {
  static bool hasMeaningfulChange({
    required DailyForecastAttentionSnapshot? lastSeen,
    required DailyForecastAttentionSnapshot current,
  }) {
    if (lastSeen == null || lastSeen.date != current.date) return true;
    if (lastSeen.status != current.status) return true;
    if ((lastSeen.predictedXp - current.predictedXp).abs() >= 5) return true;
    if ((lastSeen.targetXp - current.targetXp).abs() >= 5) return true;
    if (lastSeen.primaryFocus != current.primaryFocus) return true;

    final previousProbability = lastSeen.targetProbability;
    final currentProbability = current.targetProbability;
    if (previousProbability == null || currentProbability == null) {
      return previousProbability != currentProbability;
    }

    return (previousProbability - currentProbability).abs() >= 0.10;
  }
}

class PersonalizedDailyForecastPolicy {
  static const int minimumHistoryDays = 21;
  static const int minimumTrackedHistoryDays = 14;
  static const List<String> xpCategories = [
    'Education',
    'Work',
    'Skills',
    'Self Development',
    'Sleep',
  ];
  static const Map<String, int> _categoryCaps = {
    'Education': 20,
    'Work': 25,
    'Skills': 20,
    'Self Development': 20,
    'Sleep': 25,
  };

  static PersonalizedDailyForecast forecast({
    required DateTime date,
    required List<ExperiencePoints> history,
    required Map<String, int> todayBreakdown,
    Map<String, double> todayTrackedMinutes = const {},
    required int earnedXp,
    required int targetXp,
  }) {
    final normalizedDate = MotionDateUtils.dateOnly(date);
    final dailyHistory = _calendarHistory(
      date: normalizedDate,
      history: history,
    );
    final trackedHistoryDays =
        dailyHistory.where((entry) => entry.totalXp > 0).length;
    final hasEnoughHistory = dailyHistory.length >= minimumHistoryDays &&
        trackedHistoryDays >= minimumTrackedHistoryDays;
    final focus = _buildFocus(
      date: normalizedDate,
      history: dailyHistory,
      todayBreakdown: todayBreakdown,
      todayTrackedMinutes: todayTrackedMinutes,
      targetXp: targetXp,
    );
    final bestNextMove = _bestNextMove(focus);

    if (!hasEnoughHistory) {
      final status = earnedXp >= targetXp && targetXp > 0
          ? DailyForecastStatus.targetAchieved
          : DailyForecastStatus.learning;
      return PersonalizedDailyForecast(
        date: normalizedDate,
        earnedXp: earnedXp,
        targetXp: targetXp,
        predictedXp: earnedXp.toDouble(),
        lowerXp: earnedXp,
        upperXp: earnedXp,
        targetProbability:
            status == DailyForecastStatus.targetAchieved ? 1.0 : null,
        status: status,
        historyDays: dailyHistory.length,
        trackedHistoryDays: trackedHistoryDays,
        focus: focus,
        bestNextMove: bestNextMove,
        factors: [
          '$trackedHistoryDays tracked days are available for learning.',
          'At least $minimumTrackedHistoryDays tracked days across '
              '$minimumHistoryDays calendar days are needed.',
        ],
        hasEnoughHistory: false,
      );
    }

    final recent7Average = _average(
      dailyHistory.skip(math.max(0, dailyHistory.length - 7)),
    );
    final recent30Average = _average(
      dailyHistory.skip(math.max(0, dailyHistory.length - 30)),
    );
    final matchingWeekdays = dailyHistory
        .where((entry) => entry.date.weekday == normalizedDate.weekday)
        .toList();
    final sameWeekdayAverage = _average(
      matchingWeekdays.skip(math.max(0, matchingWeekdays.length - 12)),
    );
    final baseline = (recent7Average * 0.35) +
        (recent30Average * 0.35) +
        (sameWeekdayAverage * 0.30);
    final regression = _fitRegression(dailyHistory);
    final modelPrediction = regression == null
        ? baseline
        : (regression.prediction * 0.65) + (baseline * 0.35);
    final predictedXp = math.max(
      earnedXp.toDouble(),
      modelPrediction.clamp(0.0, MotionXpPolicy.maxDailyXp.toDouble()),
    );
    final residualDeviation = regression?.residualDeviation ??
        _standardDeviation(
          dailyHistory.skip(math.max(0, dailyHistory.length - 30)),
          recent30Average,
        );
    final uncertainty = residualDeviation.clamp(6.0, 25.0).toDouble();
    final lowerXp = math.max(
      earnedXp,
      (predictedXp - uncertainty * 0.75).floor(),
    );
    final upperXp = math.max(
      lowerXp,
      math.min(
        MotionXpPolicy.maxDailyXp,
        (predictedXp + uncertainty * 0.75).ceil(),
      ),
    );
    final probability = _targetProbability(
      earnedXp: earnedXp,
      targetXp: targetXp,
      predictedXp: predictedXp,
      uncertainty: uncertainty,
    );
    final status = _status(
      hasEnoughHistory: hasEnoughHistory,
      earnedXp: earnedXp,
      targetXp: targetXp,
      targetProbability: probability,
    );

    return PersonalizedDailyForecast(
      date: normalizedDate,
      earnedXp: earnedXp,
      targetXp: targetXp,
      predictedXp: predictedXp,
      lowerXp: lowerXp,
      upperXp: upperXp,
      targetProbability: probability,
      status: status,
      historyDays: dailyHistory.length,
      trackedHistoryDays: trackedHistoryDays,
      focus: focus,
      bestNextMove: bestNextMove,
      factors: [
        'Your last 7 days averaged ${recent7Average.round()} XP.',
        '${_weekdayName(normalizedDate.weekday)}s averaged '
            '${sameWeekdayAverage.round()} XP.',
        'The model used ${dailyHistory.length} recent calendar days and '
            '$trackedHistoryDays tracked days.',
      ],
      hasEnoughHistory: true,
    );
  }

  static List<_DailyXpVector> _calendarHistory({
    required DateTime date,
    required List<ExperiencePoints> history,
  }) {
    final rowsByDate = <String, ExperiencePoints>{};
    DateTime? firstDate;

    for (final row in history) {
      final parsedDate = MotionDateUtils.parseStoredDate(row.date);
      if (parsedDate == null || !parsedDate.isBefore(date)) continue;
      rowsByDate[MotionDateUtils.formatDbDate(parsedDate)] = row;
      if (firstDate == null || parsedDate.isBefore(firstDate)) {
        firstDate = parsedDate;
      }
    }

    if (firstDate == null) return const [];
    final earliestAllowed = date.subtract(const Duration(days: 365));
    var cursor = firstDate.isBefore(earliestAllowed)
        ? earliestAllowed
        : MotionDateUtils.dateOnly(firstDate);
    final result = <_DailyXpVector>[];

    while (cursor.isBefore(date)) {
      final row = rowsByDate[MotionDateUtils.formatDbDate(cursor)];
      result.add(_DailyXpVector.fromRow(cursor, row));
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  static _RegressionForecast? _fitRegression(
    List<_DailyXpVector> history,
  ) {
    if (history.length < 28) return null;
    final features = <List<double>>[];
    final targets = <double>[];
    final weights = <double>[];

    for (var index = 14; index < history.length; index++) {
      features.add(_featuresFor(history, index));
      targets.add(history[index].totalXp / MotionXpPolicy.maxDailyXp);
      final recency = index / history.length;
      weights.add(0.35 + (0.65 * recency));
    }

    if (features.length < 14) return null;
    final coefficients = _ridgeCoefficients(
      features: features,
      targets: targets,
      weights: weights,
    );
    if (coefficients == null) return null;

    final prediction = _dot(
          coefficients,
          _featuresFor(history, history.length),
        ) *
        MotionXpPolicy.maxDailyXp;
    var weightedSquaredError = 0.0;
    var totalWeight = 0.0;
    for (var index = 0; index < features.length; index++) {
      final residual = (targets[index] - _dot(coefficients, features[index])) *
          MotionXpPolicy.maxDailyXp;
      weightedSquaredError += weights[index] * residual * residual;
      totalWeight += weights[index];
    }

    return _RegressionForecast(
      prediction: prediction.clamp(0.0, MotionXpPolicy.maxDailyXp.toDouble()),
      residualDeviation:
          math.sqrt(weightedSquaredError / math.max(totalWeight, 1.0)),
    );
  }

  static List<double> _featuresFor(
    List<_DailyXpVector> history,
    int index,
  ) {
    final predictionDate = index < history.length
        ? history[index].date
        : history.last.date.add(const Duration(days: 1));
    final previousXp = index == 0 ? 0.0 : history[index - 1].totalXp.toDouble();
    final recent7 = history.sublist(math.max(0, index - 7), index);
    final recent28 = history.sublist(math.max(0, index - 28), index);
    final matchingWeekdays = history
        .take(index)
        .where((entry) => entry.date.weekday == predictionDate.weekday)
        .toList();
    final sameWeekday = matchingWeekdays
        .skip(math.max(0, matchingWeekdays.length - 8))
        .toList();
    final angle = 2 * math.pi * predictionDate.weekday / 7;

    return [
      1,
      previousXp / MotionXpPolicy.maxDailyXp,
      _average(recent7) / MotionXpPolicy.maxDailyXp,
      _average(recent28) / MotionXpPolicy.maxDailyXp,
      _average(sameWeekday) / MotionXpPolicy.maxDailyXp,
      math.sin(angle),
      math.cos(angle),
    ];
  }

  static List<double>? _ridgeCoefficients({
    required List<List<double>> features,
    required List<double> targets,
    required List<double> weights,
  }) {
    final columnCount = features.first.length;
    final matrix = List.generate(
      columnCount,
      (_) => List<double>.filled(columnCount, 0),
    );
    final vector = List<double>.filled(columnCount, 0);

    for (var row = 0; row < features.length; row++) {
      final weight = weights[row];
      for (var first = 0; first < columnCount; first++) {
        vector[first] += weight * features[row][first] * targets[row];
        for (var second = 0; second < columnCount; second++) {
          matrix[first][second] +=
              weight * features[row][first] * features[row][second];
        }
      }
    }

    for (var index = 1; index < columnCount; index++) {
      matrix[index][index] += 0.12;
    }
    return _solveLinearSystem(matrix, vector);
  }

  static List<double>? _solveLinearSystem(
    List<List<double>> matrix,
    List<double> vector,
  ) {
    final size = vector.length;
    final augmented = List.generate(
      size,
      (row) => [...matrix[row], vector[row]],
    );

    for (var pivot = 0; pivot < size; pivot++) {
      var bestRow = pivot;
      for (var row = pivot + 1; row < size; row++) {
        if (augmented[row][pivot].abs() > augmented[bestRow][pivot].abs()) {
          bestRow = row;
        }
      }
      if (augmented[bestRow][pivot].abs() < 1e-9) return null;
      final temporary = augmented[pivot];
      augmented[pivot] = augmented[bestRow];
      augmented[bestRow] = temporary;

      final divisor = augmented[pivot][pivot];
      for (var column = pivot; column <= size; column++) {
        augmented[pivot][column] /= divisor;
      }
      for (var row = 0; row < size; row++) {
        if (row == pivot) continue;
        final factor = augmented[row][pivot];
        for (var column = pivot; column <= size; column++) {
          augmented[row][column] -= factor * augmented[pivot][column];
        }
      }
    }

    return List.generate(size, (index) => augmented[index][size]);
  }

  static List<DailyForecastFocus> _buildFocus({
    required DateTime date,
    required List<_DailyXpVector> history,
    required Map<String, int> todayBreakdown,
    required Map<String, double> todayTrackedMinutes,
    required int targetXp,
  }) {
    final recent = history.skip(math.max(0, history.length - 30)).toList();
    final matchingWeekdays =
        history.where((entry) => entry.date.weekday == date.weekday).toList();
    final relevantWeekdays = matchingWeekdays
        .skip(math.max(0, matchingWeekdays.length - 12))
        .toList();
    final averages = <String, double>{};
    final allocations = <String, int>{};

    for (final category in xpCategories) {
      final recentAverage = _categoryAverage(recent, category);
      final weekdayAverage = _categoryAverage(relevantWeekdays, category);
      averages[category] = recentAverage * 0.65 + weekdayAverage * 0.35;
      allocations[category] = math.min(
        _categoryCaps[category]!,
        todayBreakdown[category] ?? 0,
      );
    }

    final expectedBonus = (recent.isEmpty
            ? 0.0
            : recent
                    .map((entry) => entry.categoryXp['Tracking Bonus'] ?? 0)
                    .reduce((first, second) => first + second) /
                recent.length)
        .round()
        .clamp(0, 5);
    final categoryGoal = math.max(0, targetXp - expectedBonus);
    var remaining = math.max(
      0,
      categoryGoal -
          allocations.values.fold<int>(0, (sum, value) => sum + value),
    );

    while (remaining > 0) {
      String? bestCategory;
      var bestScore = -1.0;
      for (final category in xpCategories) {
        final allocated = allocations[category]!;
        final cap = _categoryCaps[category]!;
        if (allocated >= cap) continue;
        final score = (averages[category]! + 0.75) /
            math.pow(allocated + 1, 0.65).toDouble();
        if (score > bestScore) {
          bestScore = score;
          bestCategory = category;
        }
      }
      if (bestCategory == null) break;
      allocations[bestCategory] = allocations[bestCategory]! + 1;
      remaining--;
    }

    final focus = xpCategories.map((category) {
      return DailyForecastFocus(
        category: category,
        earnedXp: todayBreakdown[category] ?? 0,
        suggestedXp: allocations[category]!,
        historicalAverageXp: averages[category]!,
        trackedMinutes: (todayTrackedMinutes[category] ?? 0).round(),
        targetMinutes: _targetMinutes(
          category: category,
          targetXp: allocations[category]!,
        ),
      );
    }).where((item) {
      return item.suggestedXp > 0 || item.historicalAverageXp > 0;
    }).toList();

    focus.sort((first, second) {
      final remainingComparison =
          second.remainingXp.compareTo(first.remainingXp);
      if (remainingComparison != 0) return remainingComparison;
      return second.historicalAverageXp.compareTo(first.historicalAverageXp);
    });
    return focus.take(3).toList(growable: false);
  }

  static DailyForecastNextMove? _bestNextMove(
    List<DailyForecastFocus> focus,
  ) {
    DailyForecastFocus? best;
    var bestScore = -1.0;
    for (final item in focus) {
      if (item.remainingXp <= 0 || item.remainingMinutes <= 0) continue;
      final score = (item.historicalAverageXp + 1) /
          math.sqrt(item.remainingMinutes.toDouble());
      if (score > bestScore) {
        best = item;
        bestScore = score;
      }
    }
    if (best == null) return null;

    final xpToEarn = best.category == 'Sleep'
        ? best.remainingXp
        : math.min(5, best.remainingXp);
    final minutesRequired = best.category == 'Sleep'
        ? best.remainingMinutes
        : math.min(best.remainingMinutes, xpToEarn * 12);
    return DailyForecastNextMove(
      category: best.category,
      xpToEarn: xpToEarn,
      minutesRequired: minutesRequired,
    );
  }

  static int _targetMinutes({
    required String category,
    required int targetXp,
  }) {
    if (targetXp <= 0) return 0;
    if (category == 'Sleep') {
      if (targetXp <= 8) return 300;
      if (targetXp <= 15) return 360;
      return 420;
    }
    return targetXp * 12;
  }

  static DailyForecastStatus _status({
    required bool hasEnoughHistory,
    required int earnedXp,
    required int targetXp,
    required double? targetProbability,
  }) {
    if (targetXp > 0 && earnedXp >= targetXp) {
      return DailyForecastStatus.targetAchieved;
    }
    if (!hasEnoughHistory) return DailyForecastStatus.learning;
    if (targetXp <= 0 || targetProbability == null) {
      return DailyForecastStatus.noTarget;
    }
    if (targetProbability >= 0.70) return DailyForecastStatus.onTrack;
    if (targetProbability >= 0.40) return DailyForecastStatus.withinReach;
    return DailyForecastStatus.atRisk;
  }

  static double? _targetProbability({
    required int earnedXp,
    required int targetXp,
    required double predictedXp,
    required double uncertainty,
  }) {
    if (targetXp <= 0) return null;
    if (earnedXp >= targetXp) return 1.0;
    final scale = math.max(6.0, uncertainty * 0.75);
    final probability = 1 / (1 + math.exp((targetXp - predictedXp) / scale));
    return probability.clamp(0.02, 0.98).toDouble();
  }

  static double _average(Iterable<_DailyXpVector> entries) {
    var count = 0;
    var total = 0.0;
    for (final entry in entries) {
      total += entry.totalXp;
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  static double _categoryAverage(
    Iterable<_DailyXpVector> entries,
    String category,
  ) {
    var count = 0;
    var total = 0.0;
    for (final entry in entries) {
      total += entry.categoryXp[category] ?? 0;
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  static double _standardDeviation(
    Iterable<_DailyXpVector> entries,
    double average,
  ) {
    var count = 0;
    var squaredDifference = 0.0;
    for (final entry in entries) {
      final difference = entry.totalXp - average;
      squaredDifference += difference * difference;
      count++;
    }
    return count <= 1 ? 10 : math.sqrt(squaredDifference / (count - 1));
  }

  static double _dot(List<double> first, List<double> second) {
    var total = 0.0;
    for (var index = 0; index < first.length; index++) {
      total += first[index] * second[index];
    }
    return total;
  }

  static String _weekdayName(int weekday) {
    return const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][weekday - 1];
  }
}

class _DailyXpVector {
  const _DailyXpVector({
    required this.date,
    required this.categoryXp,
    required this.totalXp,
  });

  factory _DailyXpVector.fromRow(
    DateTime date,
    ExperiencePoints? row,
  ) {
    final categoryXp = <String, int>{
      'Education': row?.educationXP ?? 0,
      'Work': row?.workXP ?? 0,
      'Skills': row?.skillsXP ?? 0,
      'Self Development': row?.sdXP ?? 0,
      'Sleep': row?.sleepXP ?? 0,
      'Tracking Bonus': row?.accountabilityBonusXP ?? 0,
    };
    return _DailyXpVector(
      date: date,
      categoryXp: categoryXp,
      totalXp: categoryXp.values.fold<int>(0, (sum, value) => sum + value),
    );
  }

  final DateTime date;
  final Map<String, int> categoryXp;
  final int totalXp;
}

class _RegressionForecast {
  const _RegressionForecast({
    required this.prediction,
    required this.residualDeviation,
  });

  final double prediction;
  final double residualDeviation;
}
