import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:motion/motion_core/mc_sql_table/activity_timer_session.dart';

abstract class ActivityTimerNotificationBridge {
  Future<bool> requestPermission({required bool requiresExactAlarm});

  Future<void> sync({
    required ActivityTimerSession session,
    required int elapsedSeconds,
  });

  Future<void> targetReached({
    required ActivityTimerSession session,
    required int elapsedSeconds,
  });

  Future<void> dismissTargetAlert();

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
  Future<bool> requestPermission({required bool requiresExactAlarm}) async {
    if (!_isSupported) return true;
    return await _channel.invokeMethod<bool>(
          'requestPermission',
          {'requiresExactAlarm': requiresExactAlarm},
        ) ??
        false;
  }

  @override
  Future<void> sync({
    required ActivityTimerSession session,
    required int elapsedSeconds,
  }) async {
    if (!_isSupported) return;
    await _channel.invokeMethod<void>(
      'sync',
      _arguments(session: session, elapsedSeconds: elapsedSeconds),
    );
  }

  @override
  Future<void> targetReached({
    required ActivityTimerSession session,
    required int elapsedSeconds,
  }) async {
    if (!_isSupported) return;
    await _channel.invokeMethod<void>(
      'targetReached',
      _arguments(session: session, elapsedSeconds: elapsedSeconds),
    );
  }

  @override
  Future<void> dismissTargetAlert() async {
    if (!_isSupported) return;
    await _channel.invokeMethod<void>('dismissTargetAlert');
  }

  Map<String, Object?> _arguments({
    required ActivityTimerSession session,
    required int elapsedSeconds,
  }) {
    return {
      'mainCategoryName': session.mainCategoryName,
      'subcategoryName': session.subcategoryName,
      'elapsedSeconds': elapsedSeconds,
      'isRunning': session.isRunning,
      'timerStartedAtEpochMs': session.startedAtEpochMs,
      'targetSeconds': session.activeTargetSeconds,
      'targetAlertTriggered': session.targetAlertTriggered,
      'timerMode': session.effectiveMode.name,
      'pomodoroPhase': session.pomodoroPhase?.name,
      'pomodoroFocusSeconds': session.pomodoroFocusSeconds,
      'pomodoroShortBreakSeconds': session.pomodoroShortBreakSeconds,
      'pomodoroLongBreakSeconds': session.pomodoroLongBreakSeconds,
      'pomodoroTotalRounds': session.pomodoroTotalRounds,
      'pomodoroCurrentRound': session.pomodoroCurrentRound,
      'pomodoroPhaseStartedAtEpochMs': session.pomodoroPhaseStartedAtEpochMs,
    };
  }

  @override
  Future<void> stop() async {
    if (!_isSupported) return;
    await _channel.invokeMethod<void>('stop');
  }
}
