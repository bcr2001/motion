class TrackingTimePolicy {
  static const double maxDailyMinutes = 24 * 60;
  static const double _tolerance = 0.000001;

  static void validateBlock(double minutes) {
    if (!minutes.isFinite || minutes < 0) {
      throw const InvalidTrackingDuration();
    }
    if (minutes > maxDailyMinutes + _tolerance) {
      throw const TimeBlockLimitExceeded();
    }
  }

  static void validateDailyTotal({
    required double existingMinutes,
    required double additionalMinutes,
    required String date,
  }) {
    if (!additionalMinutes.isFinite || additionalMinutes < 0) {
      throw const InvalidTrackingDuration();
    }
    if (existingMinutes + additionalMinutes <= maxDailyMinutes + _tolerance) {
      return;
    }

    throw DailyTimeLimitExceeded(
      date: date,
      remainingMinutes: (maxDailyMinutes - existingMinutes).clamp(
        0,
        maxDailyMinutes,
      ),
    );
  }

  static String formatMinutes(double totalMinutes) {
    final totalSeconds = (totalMinutes * 60).round().clamp(0, 86400);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0 || parts.isEmpty) parts.add('${seconds}s');
    return parts.join(' ');
  }
}

sealed class TrackingTimeLimitException implements Exception {
  const TrackingTimeLimitException();
}

class InvalidTrackingDuration extends TrackingTimeLimitException {
  const InvalidTrackingDuration();

  @override
  String toString() => 'Tracked time must be a valid positive duration.';
}

class TimeBlockLimitExceeded extends TrackingTimeLimitException {
  const TimeBlockLimitExceeded();

  @override
  String toString() => 'A single time block cannot exceed 24 hours.';
}

class DailyTimeLimitExceeded extends TrackingTimeLimitException {
  const DailyTimeLimitExceeded({
    required this.date,
    required this.remainingMinutes,
  });

  final String date;
  final double remainingMinutes;

  @override
  String toString() {
    if (remainingMinutes <= 0) {
      return 'You already have 24 hours tracked for $date.';
    }
    return 'Only ${TrackingTimePolicy.formatMinutes(remainingMinutes)} '
        'remain available for $date.';
  }
}
