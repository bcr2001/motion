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
    String? Function(String currentUser)? motionEmailForUser,
  })  : _userUidProvider = userUidProvider,
        _csvTransfer = csvTransfer ?? MotionCsvDataTransfer(),
        _driveBackupService = driveBackupService ?? GoogleDriveBackupService(),
        _motionEmailForUser =
            motionEmailForUser ?? _firebaseEmailForCurrentUser {
    WidgetsBinding.instance.addObserver(this);
    _userUidProvider.addListener(_handleUserChanged);
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
  final String? Function(String currentUser) _motionEmailForUser;

  SharedPreferences? _prefs;
  Timer? _retryTimer;
  Timer? _eligibilityTimer;
  String? _loadedUser;
  String? _activeBackupUser;
  int _accountGeneration = 0;
  bool _isEnabled = false;
  AutoDriveBackupStatus _status = AutoDriveBackupStatus.idle;
  String? _lastSuccessAt;
  String? _lastAttemptAt;
  String _message = 'Automatic Google Drive backup is off.';

  bool get isEnabled => _isEnabled;
  bool get isRunning => _activeBackupUser == _loadedUser;
  AutoDriveBackupStatus get status => _status;
  String? get lastSuccessAt => _lastSuccessAt;
  String? get lastAttemptAt => _lastAttemptAt;
  String get message => _message;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _removeUnscopedLegacyState();
    await _loadStateForUser(_userUidProvider.userUid);
  }

  Future<void> setEnabled(bool enabled) async {
    final currentUser = _userUidProvider.userUid;
    if (currentUser == null || currentUser != _loadedUser || _prefs == null) {
      throw StateError(
        'Your Motion account is still loading. Please try again.',
      );
    }

    final generation = _accountGeneration;
    _isEnabled = enabled;
    await _prefs!.setBool(_userKey(_enabledKey, currentUser), enabled);
    if (generation != _accountGeneration || currentUser != _loadedUser) return;

    if (!enabled) {
      _retryTimer?.cancel();
      _eligibilityTimer?.cancel();
      _status = AutoDriveBackupStatus.idle;
      _message = 'Automatic Google Drive backup is off.';
      await _saveStatus(currentUser: currentUser);
      notifyListeners();
      return;
    }

    _message = 'Automatic backup is on. Motion will back up after 8 PM.';
    await _saveStatus(currentUser: currentUser);
    notifyListeners();
    unawaited(runBackupIfEligible(force: true));
  }

  Future<void> runBackupIfEligible({bool force = false}) async {
    final currentUser = _userUidProvider.userUid;
    if (currentUser == null) {
      return;
    }
    if (_loadedUser != currentUser) {
      await _loadStateForUser(currentUser);
    }
    if (!_isEnabled || _activeBackupUser != null) return;
    final generation = _accountGeneration;

    final expectedEmail = _motionEmailForUser(currentUser)?.trim();
    if (expectedEmail == null || expectedEmail.isEmpty) {
      _status = AutoDriveBackupStatus.blocked;
      _message =
          'Motion could not verify your account email. Automatic backup did not run.';
      await _saveStatus(currentUser: currentUser);
      if (generation == _accountGeneration && currentUser == _loadedUser) {
        notifyListeners();
      }
      return;
    }

    final now = DateTime.now();
    final today = MotionDateUtils.formatDbDate(now);
    final lastSuccessDate =
        _prefs?.getString(_userKey(_lastSuccessDateKey, currentUser));
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
      await _saveStatus(currentUser: currentUser);
      if (generation == _accountGeneration && currentUser == _loadedUser) {
        notifyListeners();
      }
      return;
    }

    await _runBackup(
      currentUser: currentUser,
      expectedEmail: expectedEmail,
    );
  }

  Future<void> recordSuccessfulBackup({
    required String currentUser,
    required int fileCount,
  }) async {
    if (currentUser != _loadedUser) return;
    _retryTimer?.cancel();
    final completedAt = DateTime.now();
    await _prefs?.setString(
      _userKey(_lastSuccessDateKey, currentUser),
      MotionDateUtils.formatDbDate(completedAt),
    );
    if (currentUser != _loadedUser) return;

    _scheduleEveningBackupWindow(completedAt);
    _lastSuccessAt = completedAt.toIso8601String();
    _status = AutoDriveBackupStatus.success;
    _message = 'Last Google Drive backup saved $fileCount file(s).';
    await _saveStatus(currentUser: currentUser);
    notifyListeners();
  }

  Future<void> _runBackup({
    required String currentUser,
    required String expectedEmail,
  }) async {
    _retryTimer?.cancel();
    _eligibilityTimer?.cancel();
    _activeBackupUser = currentUser;
    _status = AutoDriveBackupStatus.running;
    _lastAttemptAt = DateTime.now().toIso8601String();
    _message = 'Automatic Google Drive backup is running...';
    await _saveStatus(currentUser: currentUser);
    notifyListeners();

    try {
      final backupFiles = await _csvTransfer.backupFiles(
        currentUser: currentUser,
      );
      final result = await _driveBackupService.uploadBackupFiles(
        files: backupFiles,
        expectedEmail: expectedEmail,
        allowInteractiveSignIn: false,
      );

      if (currentUser != _loadedUser) return;

      final completedAt = DateTime.now();
      await _prefs?.setString(
        _userKey(_lastSuccessDateKey, currentUser),
        MotionDateUtils.formatDbDate(completedAt),
      );
      if (currentUser != _loadedUser) return;

      _lastSuccessAt = completedAt.toIso8601String();
      _status = AutoDriveBackupStatus.success;
      _message =
          'Last automatic backup saved ${result.fileCount} file(s) to Google Drive.';
      _scheduleEveningBackupWindow(completedAt);
    } on StateError catch (error) {
      if (currentUser == _loadedUser) {
        _handleBackupFailure(error.message);
      }
    } catch (error) {
      if (currentUser == _loadedUser) {
        _handleBackupFailure('$error');
      }
    } finally {
      _activeBackupUser = null;
      if (currentUser == _loadedUser) {
        await _saveStatus(currentUser: currentUser);
        notifyListeners();
      } else if (_isEnabled) {
        _scheduleEligibilityCheck();
      }
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

  void _handleUserChanged() {
    unawaited(_loadStateForUser(_userUidProvider.userUid));
  }

  Future<void> _loadStateForUser(String? currentUser) async {
    final generation = ++_accountGeneration;
    _retryTimer?.cancel();
    _eligibilityTimer?.cancel();
    _loadedUser = currentUser;

    if (currentUser == null || _prefs == null) {
      _resetVisibleState();
      notifyListeners();
      return;
    }

    final prefs = _prefs!;
    final isEnabled =
        prefs.getBool(_userKey(_enabledKey, currentUser)) ?? false;
    final lastSuccessAt =
        prefs.getString(_userKey(_lastSuccessAtKey, currentUser));
    final lastAttemptAt =
        prefs.getString(_userKey(_lastAttemptAtKey, currentUser));
    final message = prefs.getString(_userKey(_lastMessageKey, currentUser));
    final status = _statusFromName(
      prefs.getString(_userKey(_lastStatusKey, currentUser)),
    );

    if (generation != _accountGeneration || currentUser != _loadedUser) return;
    _isEnabled = isEnabled;
    _lastSuccessAt = lastSuccessAt;
    _lastAttemptAt = lastAttemptAt;
    _message = message ?? 'Automatic Google Drive backup is off.';
    _status = status;
    notifyListeners();

    if (_isEnabled) _scheduleEligibilityCheck();
  }

  void _resetVisibleState() {
    _isEnabled = false;
    _lastSuccessAt = null;
    _lastAttemptAt = null;
    _status = AutoDriveBackupStatus.idle;
    _message = 'Automatic Google Drive backup is off.';
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

  Future<void> _saveStatus({required String currentUser}) async {
    final prefs = _prefs;
    if (prefs == null) return;

    final statusName = _status.name;
    final message = _message;
    final lastSuccessAt = _lastSuccessAt;
    final lastAttemptAt = _lastAttemptAt;

    await prefs.setString(
      _userKey(_lastStatusKey, currentUser),
      statusName,
    );
    await prefs.setString(
      _userKey(_lastMessageKey, currentUser),
      message,
    );
    if (lastSuccessAt != null) {
      await prefs.setString(
        _userKey(_lastSuccessAtKey, currentUser),
        lastSuccessAt,
      );
    }
    if (lastAttemptAt != null) {
      await prefs.setString(
        _userKey(_lastAttemptAtKey, currentUser),
        lastAttemptAt,
      );
    }
  }

  String _userKey(String key, String currentUser) => '$key.$currentUser';

  Future<void> _removeUnscopedLegacyState() async {
    final prefs = _prefs;
    if (prefs == null) return;
    for (final key in const [
      _enabledKey,
      _lastSuccessAtKey,
      _lastSuccessDateKey,
      _lastAttemptAtKey,
      _lastMessageKey,
      _lastStatusKey,
    ]) {
      await prefs.remove(key);
    }
  }

  static String? _firebaseEmailForCurrentUser(String currentUser) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != currentUser) return null;
    return firebaseUser.email;
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
    _userUidProvider.removeListener(_handleUserChanged);
    _retryTimer?.cancel();
    _eligibilityTimer?.cancel();
    super.dispose();
  }
}
