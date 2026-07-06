import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_cloud/google_drive_backup_service.dart';
import 'package:motion/motion_core/mc_csv/csv_data_transfer.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AutoDriveBackupStatus {
  idle,
  running,
  success,
  pendingOffline,
  blocked,
  noData,
}

class AutoDriveBackupProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  AutoDriveBackupProvider({
    required UserUidProvider userUidProvider,
    MotionCsvDataTransfer? csvTransfer,
    GoogleDriveBackupService? driveBackupService,
  })  : _userUidProvider = userUidProvider,
        _csvTransfer = csvTransfer ?? MotionCsvDataTransfer(),
        _driveBackupService =
            driveBackupService ?? GoogleDriveBackupService() {
    WidgetsBinding.instance.addObserver(this);
    _userUidProvider.addListener(_scheduleEligibilityCheck);
  }

  static const int eveningBackupHour = 20;
  static const _enabledKey = 'autoDriveBackupEnabled';
  static const _lastSuccessAtKey = 'autoDriveBackupLastSuccessAt';
  static const _lastSuccessDateKey = 'autoDriveBackupLastSuccessDate';
  static const _lastAttemptAtKey = 'autoDriveBackupLastAttemptAt';
  static const _lastMessageKey = 'autoDriveBackupLastMessage';
  static const _lastStatusKey = 'autoDriveBackupLastStatus';

  final UserUidProvider _userUidProvider;
  final MotionCsvDataTransfer _csvTransfer;
  final GoogleDriveBackupService _driveBackupService;

  SharedPreferences? _prefs;
  Timer? _retryTimer;
  Timer? _eligibilityTimer;
  bool _isEnabled = false;
  bool _isRunning = false;
  AutoDriveBackupStatus _status = AutoDriveBackupStatus.idle;
  String? _lastSuccessAt;
  String? _lastAttemptAt;
  String _message = 'Automatic Google Drive backup is off.';

  bool get isEnabled => _isEnabled;
  bool get isRunning => _isRunning;
  AutoDriveBackupStatus get status => _status;
  String? get lastSuccessAt => _lastSuccessAt;
  String? get lastAttemptAt => _lastAttemptAt;
  String get message => _message;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isEnabled = _prefs?.getBool(_enabledKey) ?? false;
    _lastSuccessAt = _prefs?.getString(_lastSuccessAtKey);
    _lastAttemptAt = _prefs?.getString(_lastAttemptAtKey);
    _message = _prefs?.getString(_lastMessageKey) ?? _message;
    _status = _statusFromName(_prefs?.getString(_lastStatusKey));

    if (_isEnabled) _scheduleEligibilityCheck();
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _prefs?.setBool(_enabledKey, enabled);

    if (!enabled) {
      _retryTimer?.cancel();
      _eligibilityTimer?.cancel();
      _status = AutoDriveBackupStatus.idle;
      _message = 'Automatic Google Drive backup is off.';
      await _saveStatus();
      notifyListeners();
      return;
    }

    _message = 'Automatic backup is on. Motion will back up after 8 PM.';
    await _saveStatus();
    notifyListeners();
    unawaited(runBackupIfEligible(force: true));
  }

  Future<void> runBackupIfEligible({bool force = false}) async {
    if (!_isEnabled || _isRunning) return;

    final currentUser = _userUidProvider.userUid;
    if (currentUser == null) {
      _message = 'Waiting for your account to finish loading.';
      _status = AutoDriveBackupStatus.idle;
      await _saveStatus();
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final today = MotionDateUtils.formatDbDate(now);
    final lastSuccessDate = _prefs?.getString(_lastSuccessDateKey);
    final isEveningWindow = now.hour >= eveningBackupHour;
    final missedEarlierBackup = lastSuccessDate != null &&
        lastSuccessDate.compareTo(today) < 0 &&
        now.hour < eveningBackupHour;

    if (!force &&
        lastSuccessDate == today &&
        _status == AutoDriveBackupStatus.success) {
      return;
    }
    if (!force && !isEveningWindow && !missedEarlierBackup) {
      _message = 'Next automatic backup window opens after 8 PM.';
      _status = AutoDriveBackupStatus.idle;
      _scheduleEveningBackupWindow(now);
      await _saveStatus();
      notifyListeners();
      return;
    }

    await _runBackup(currentUser: currentUser);
  }

  Future<void> recordSuccessfulBackup({
    required int fileCount,
    required bool emailMatchesMotionAccount,
  }) async {
    _retryTimer?.cancel();
    _scheduleEveningBackupWindow(DateTime.now());
    _lastSuccessAt = DateTime.now().toIso8601String();
    await _prefs?.setString(
      _lastSuccessDateKey,
      MotionDateUtils.todayIso(),
    );
    _status = AutoDriveBackupStatus.success;
    _message = emailMatchesMotionAccount
        ? 'Last Google Drive backup saved $fileCount file(s).'
        : 'Backup saved, but the Drive account differs from your Motion email.';
    await _saveStatus();
    notifyListeners();
  }

  Future<void> _runBackup({required String currentUser}) async {
    _retryTimer?.cancel();
    _eligibilityTimer?.cancel();
    _isRunning = true;
    _status = AutoDriveBackupStatus.running;
    _lastAttemptAt = DateTime.now().toIso8601String();
    _message = 'Automatic Google Drive backup is running...';
    await _saveStatus();
    notifyListeners();

    try {
      final backupFiles = await _csvTransfer.backupFiles(
        currentUser: currentUser,
      );
      final result = await _driveBackupService.uploadBackupFiles(
        files: backupFiles,
        expectedEmail: FirebaseAuth.instance.currentUser?.email,
        allowInteractiveSignIn: false,
      );

      _lastSuccessAt = DateTime.now().toIso8601String();
      await _prefs?.setString(
        _lastSuccessDateKey,
        MotionDateUtils.todayIso(),
      );
      _status = AutoDriveBackupStatus.success;
      _message = result.emailMatchesMotionAccount
          ? 'Last automatic backup saved ${result.fileCount} file(s) to Google Drive.'
          : 'Backup saved, but the Drive account differs from your Motion email.';
      _scheduleEveningBackupWindow(DateTime.now());
    } on StateError catch (error) {
      _handleBackupFailure(error.message);
    } catch (error) {
      _handleBackupFailure('$error');
    } finally {
      _isRunning = false;
      await _saveStatus();
      notifyListeners();
    }
  }

  void _handleBackupFailure(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('no internet') ||
        lowerMessage.contains('network') ||
        lowerMessage.contains('host lookup')) {
      _status = AutoDriveBackupStatus.pendingOffline;
      _message = 'Backup pending. Motion will retry when the app is open.';
      _scheduleRetry();
      return;
    }

    if (lowerMessage.contains('no motion data') ||
        lowerMessage.contains('no data') ||
        lowerMessage.contains('export yet')) {
      _status = AutoDriveBackupStatus.noData;
      _message = 'Automatic backup is on, but there is no data to back up yet.';
      return;
    }

    _status = AutoDriveBackupStatus.blocked;
    _message = message;
  }

  void _scheduleEligibilityCheck() {
    if (!_isEnabled) return;
    unawaited(Future.microtask(() => runBackupIfEligible()));
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 15), () {
      unawaited(runBackupIfEligible(force: true));
    });
  }

  void _scheduleEveningBackupWindow(DateTime now) {
    if (!_isEnabled) return;

    _eligibilityTimer?.cancel();
    final todaysWindow = DateTime(
      now.year,
      now.month,
      now.day,
      eveningBackupHour,
    );
    final nextWindow = now.isBefore(todaysWindow)
        ? todaysWindow
        : DateTime(now.year, now.month, now.day + 1, eveningBackupHour);
    _eligibilityTimer = Timer(nextWindow.difference(now), () {
      unawaited(runBackupIfEligible());
    });
  }

  Future<void> _saveStatus() async {
    await _prefs?.setString(_lastStatusKey, _status.name);
    await _prefs?.setString(_lastMessageKey, _message);
    if (_lastSuccessAt != null) {
      await _prefs?.setString(_lastSuccessAtKey, _lastSuccessAt!);
    }
    if (_lastAttemptAt != null) {
      await _prefs?.setString(_lastAttemptAtKey, _lastAttemptAt!);
    }
  }

  AutoDriveBackupStatus _statusFromName(String? value) {
    for (final status in AutoDriveBackupStatus.values) {
      if (status.name == value) return status;
    }
    return AutoDriveBackupStatus.idle;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(runBackupIfEligible());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userUidProvider.removeListener(_scheduleEligibilityCheck);
    _retryTimer?.cancel();
    _eligibilityTimer?.cancel();
    super.dispose();
  }
}
