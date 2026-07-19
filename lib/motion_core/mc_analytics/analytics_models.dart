class ReportSnapshot {
  final int trackedDays;
  final double accountedMinutes;
  final double unaccountedMinutes;
  final int totalXp;
  final int xpDays;
  final double efficiencyScore;
  final String? bestDay;
  final int bestDayXp;
  final String? lowestDay;
  final int lowestDayXp;

  const ReportSnapshot({
    required this.trackedDays,
    required this.accountedMinutes,
    required this.unaccountedMinutes,
    required this.totalXp,
    required this.xpDays,
    required this.efficiencyScore,
    required this.bestDay,
    required this.bestDayXp,
    required this.lowestDay,
    required this.lowestDayXp,
  });

  factory ReportSnapshot.fromMap(Map<String, dynamic> map) {
    return ReportSnapshot(
      trackedDays: _readInt(map['trackedDays']),
      accountedMinutes: _readDouble(map['accountedMinutes']),
      unaccountedMinutes: _readDouble(map['unaccountedMinutes']),
      totalXp: _readInt(map['totalXp']),
      xpDays: _readInt(map['xpDays']),
      efficiencyScore: _readDouble(map['efficiencyScore']),
      bestDay: _readNullableString(map['bestDay']),
      bestDayXp: _readInt(map['bestDayXp']),
      lowestDay: _readNullableString(map['lowestDay']),
      lowestDayXp: _readInt(map['lowestDayXp']),
    );
  }

  static const empty = ReportSnapshot(
    trackedDays: 0,
    accountedMinutes: 0,
    unaccountedMinutes: 0,
    totalXp: 0,
    xpDays: 0,
    efficiencyScore: 0,
    bestDay: null,
    bestDayXp: 0,
    lowestDay: null,
    lowestDayXp: 0,
  );
}

class DailyXpPoint {
  final String date;
  final int totalXp;

  const DailyXpPoint({required this.date, required this.totalXp});

  factory DailyXpPoint.fromMap(Map<String, dynamic> map) {
    return DailyXpPoint(
      date: map['date']?.toString() ?? '',
      totalXp: _readInt(map['totalXp']),
    );
  }
}

class CategoryTimeTotal {
  final String mainCategoryName;
  final double totalHours;

  const CategoryTimeTotal({
    required this.mainCategoryName,
    required this.totalHours,
  });

  factory CategoryTimeTotal.fromMap(Map<String, dynamic> map) {
    return CategoryTimeTotal(
      mainCategoryName: map['mainCategoryName']?.toString() ?? 'Unknown',
      totalHours: _readDouble(map['totalTimeSpent']),
    );
  }
}

class SubcategoryTimeTotal {
  final String subcategoryName;
  final String mainCategoryName;
  final double totalMinutes;

  const SubcategoryTimeTotal({
    required this.subcategoryName,
    required this.mainCategoryName,
    required this.totalMinutes,
  });

  factory SubcategoryTimeTotal.fromMap(Map<String, dynamic> map) {
    return SubcategoryTimeTotal(
      subcategoryName: map['subcategoryName']?.toString() ?? 'Unknown',
      mainCategoryName: map['mainCategoryName']?.toString() ?? 'Unknown',
      totalMinutes: _readDouble(map['totalTimeSpent']),
    );
  }
}

int _readInt(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _readNullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
