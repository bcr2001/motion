import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:motion/motion_core/mc_sql_table/activity_timer_session.dart';

abstract class ActivityTimerNotificationBridge {
  Future<bool> requestPermission();

  Future<void> sync({
    required ActivityTimerSession session,
    required int elapsedSeconds,
  });

  Future<void> stop();
}

class PlatformActivityTimerNotificationBridge
    implements ActivityTimerNotificationBridge {
  static const MethodChannel _channel = MethodChannel(
    'motion/activity_timer_notification',
  );

  bool get _isSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isSupported) return true;
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  @override
  Future<void> sync({
    required ActivityTimerSession session,
    required int elapsedSeconds,
  }) async {
    if (!_isSupported) return;
    await _channel.invokeMethod<void>('sync', {
      'mainCategoryName': session.mainCategoryName,
      'subcategoryName': session.subcategoryName,
      'elapsedSeconds': elapsedSeconds,
      'isRunning': session.isRunning,
    });
  }

  @override
  Future<void> stop() async {
    if (!_isSupported) return;
    await _channel.invokeMethod<void>('stop');
  }
}
