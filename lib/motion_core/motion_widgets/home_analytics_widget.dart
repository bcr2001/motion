import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';

class HomeAnalyticsWidget {
  static const MethodChannel _channel = MethodChannel('motion/home_widget');

  static Future<void> update({
    required int todayXp,
    required int targetXp,
    required int currentStreak,
    required EfsBadge badge,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final progress = targetXp <= 0
        ? 1.0
        : (todayXp / targetXp).clamp(0.0, 1.0).toDouble();

    try {
      await _channel.invokeMethod<void>('update', {
        'todayXp': todayXp,
        'targetXp': targetXp,
        'currentStreak': currentStreak,
        'badgeLevel': badge.level.name,
        'badgeName': badge.name,
        'progress': progress,
      });
    } on PlatformException {
      // A home-screen widget is optional; app rendering should never depend on it.
    }
  }
}
