import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/activity_timer_session.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';
import 'package:motion/motion_core/mc_sqlite/tracking_time_policy.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/tracking_data_revisions.dart';
import 'package:motion/motion_core/motion_providers/timer_pvd/activity_timer_pvd.dart';
import 'package:motion/motion_core/motion_services/activity_timer_notification_bridge.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActivityTimerSession', () {
    test('round-trips persisted running timer state', () {
      final session = ActivityTimerSession(
        currentLoggedInUser: 'user-1',
        mainCategoryName: 'Skills',
        subcategoryName: 'Chess',
        startedAtEpochMs: DateTime(2026, 7, 19, 9).millisecondsSinceEpoch,
        currentSegmentStartedAtEpochMs:
            DateTime(2026, 7, 19, 10).millisecondsSinceEpoch,
        completedSegments: [
          ActivityTimerSegment(
            startedAtEpochMs: DateTime(2026, 7, 19, 9).millisecondsSinceEpoch,
            endedAtEpochMs: DateTime(2026, 7, 19, 9, 30).millisecondsSinceEpoch,
          ),
        ],
        status: ActivityTimerStatus.running,
        updatedAtEpochMs: DateTime(2026, 7, 19, 10).millisecondsSinceEpoch,
        nextReminderAtSeconds: 7200,
        targetSeconds: 2 * 60 * 60,
        targetAlertTriggered: true,
      );

      final restored = ActivityTimerSession.fromMap(session.toMap());

      expect(restored.currentLoggedInUser, 'user-1');
      expect(restored.subcategoryName, 'Chess');
      expect(restored.isRunning, isTrue);
      expect(restored.targetSeconds, 2 * 60 * 60);
      expect(restored.targetAlertTriggered, isTrue);
      expect(restored.completedSegments, hasLength(1));
      expect(
        restored.elapsedSecondsAt(DateTime(2026, 7, 19, 10, 15)),
        45 * 60,
      );
    });

    test('paused timers do not accrue additional time', () {
      final session = ActivityTimerSession(
        currentLoggedInUser: 'user-1',
        mainCategoryName: 'Education',
        subcategoryName: 'Studied/Revised',
        startedAtEpochMs: DateTime(2026, 7, 19, 9).millisecondsSinceEpoch,
        currentSegmentStartedAtEpochMs: null,
        completedSegments: [
          ActivityTimerSegment(
            startedAtEpochMs: DateTime(2026, 7, 19, 9).millisecondsSinceEpoch,
            endedAtEpochMs: DateTime(2026, 7, 19, 9, 25).millisecondsSinceEpoch,
          ),
        ],
        status: ActivityTimerStatus.paused,
        updatedAtEpochMs: DateTime(2026, 7, 19, 9, 25).millisecondsSinceEpoch,
        nextReminderAtSeconds: 7200,
      );

      expect(
        session.elapsedSecondsAt(DateTime(2026, 7, 20, 12)),
        25 * 60,
      );
    });

    test('calculates remaining target time and overtime', () {
      final start = DateTime(2026, 7, 19, 9);
      final session = ActivityTimerSession(
        currentLoggedInUser: 'user-1',
        mainCategoryName: 'Skills',
        subcategoryName: 'Chess',
        startedAtEpochMs: start.millisecondsSinceEpoch,
        currentSegmentStartedAtEpochMs: start.millisecondsSinceEpoch,
        completedSegments: const [],
        status: ActivityTimerStatus.running,
        updatedAtEpochMs: start.millisecondsSinceEpoch,
        nextReminderAtSeconds: 7200,
        targetSeconds: 60 * 60,
      );

      expect(session.remainingSecondsAt(start.add(const Duration(minutes: 20))),
          40 * 60);
      expect(
          session.targetReachedAt(start.add(const Duration(hours: 1))), isTrue);
      expect(session.overtimeSecondsAt(start.add(const Duration(minutes: 75))),
          15 * 60);
    });

    test('projects the finish time around paused duration', () {
      final start = DateTime(2026, 8, 11, 12);
      final runningSession = ActivityTimerSession(
        currentLoggedInUser: 'user-1',
        mainCategoryName: 'Education',
        subcategoryName: 'Studied/Revised',
        startedAtEpochMs: start.millisecondsSinceEpoch,
        currentSegmentStartedAtEpochMs: start.millisecondsSinceEpoch,
        completedSegments: const [],
        status: ActivityTimerStatus.running,
        updatedAtEpochMs: start.millisecondsSinceEpoch,
        nextReminderAtSeconds: 7200,
        targetSeconds: 20 * 60,
      );

      expect(
        runningSession.expectedEndAt(
          start.add(const Duration(minutes: 5)),
        ),
        DateTime(2026, 8, 11, 12, 20),
      );

      final pausedSession = runningSession.copyWith(
        currentSegmentStartedAtEpochMs: null,
        completedSegments: [
          ActivityTimerSegment(
            startedAtEpochMs: start.millisecondsSinceEpoch,
            endedAtEpochMs:
                start.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
          ),
        ],
        status: ActivityTimerStatus.paused,
      );

      expect(
        pausedSession.expectedEndAt(
          start.add(const Duration(minutes: 10)),
        ),
        DateTime(2026, 8, 11, 12, 25),
      );
    });
  });

  group('activity timer calculations', () {
    test('splits active intervals accurately at midnight', () {
      final totals = splitTimerSegmentsByDate([
        ActivityTimerSegment(
          startedAtEpochMs:
              DateTime(2026, 7, 19, 23, 50).millisecondsSinceEpoch,
          endedAtEpochMs: DateTime(2026, 7, 20, 0, 20).millisecondsSinceEpoch,
        ),
      ]);

      expect(totals['2026-07-19'], 10 * 60);
      expect(totals['2026-07-20'], 20 * 60);
    });

    test('keeps paused gaps out of date totals', () {
      final totals = splitTimerSegmentsByDate([
        ActivityTimerSegment(
          startedAtEpochMs:
              DateTime(2026, 7, 19, 23, 55).millisecondsSinceEpoch,
          endedAtEpochMs: DateTime(2026, 7, 20, 0, 5).millisecondsSinceEpoch,
        ),
        ActivityTimerSegment(
          startedAtEpochMs: DateTime(2026, 7, 20, 1).millisecondsSinceEpoch,
          endedAtEpochMs: DateTime(2026, 7, 20, 1, 15).millisecondsSinceEpoch,
        ),
      ]);

      expect(totals['2026-07-19'], 5 * 60);
      expect(totals['2026-07-20'], 20 * 60);
    });

    test('formats timer duration without losing hours', () {
      expect(formatActivityTimerDuration(5 * 3600 + 7 * 60 + 9), '05:07:09');
    });
  });

  group('activity timer database integration', () {
    late Database database;
    late TrackerDatabaseHelper databaseHelper;
    late TrackingDataRevisions revisions;
    late SubcategoryTrackerDatabaseProvider subcategoryProvider;
    late UserUidProvider userProvider;
    late ActivityTimerProvider timer;
    late _FakeActivityTimerNotificationBridge notificationBridge;
    late DateTime now;

    setUpAll(sqfliteFfiInit);

    setUp(() async {
      database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: TrackerDatabaseSchema.version,
          onConfigure: TrackerDatabaseSchema.configure,
          onCreate: (database, version) =>
              TrackerDatabaseSchema.create(database),
        ),
      );
      databaseHelper = TrackerDatabaseHelper.forDatabase(database);
      revisions = TrackingDataRevisions();
      subcategoryProvider = SubcategoryTrackerDatabaseProvider(
        revisions: revisions,
        databaseHelper: databaseHelper,
      );
      userProvider = UserUidProvider(
        initialUserUid: 'user-1',
        isInitialized: true,
      );
      now = DateTime(2026, 7, 19, 9);
      notificationBridge = _FakeActivityTimerNotificationBridge();
      timer = ActivityTimerProvider(
        userUidProvider: userProvider,
        subcategoryProvider: subcategoryProvider,
        databaseHelper: databaseHelper,
        notificationBridge: notificationBridge,
        clock: () => now,
      );
      await timer.initialize();
      notificationBridge.events.clear();
    });

    tearDown(() async {
      timer.dispose();
      subcategoryProvider.dispose();
      revisions.dispose();
      userProvider.dispose();
      await database.close();
    });

    test(
      'start, restore, pause, resume, and finish update all database views',
      () async {
        await timer.start(
          mainCategoryName: MotionCategories.skills,
          subcategoryName: 'Chess',
        );
        expect(notificationBridge.lastPermissionRequiredExactAlarm, isFalse);

        var timerRows = await database.query(
          MotionDbTables.activeTimerSession,
        );
        expect(timerRows, hasLength(1));
        expect(
          timerRows.single[MotionDbColumns.timerStatus],
          ActivityTimerStatus.running.name,
        );

        now = DateTime(2026, 7, 19, 9, 20);
        timer.dispose();
        timer = ActivityTimerProvider(
          userUidProvider: userProvider,
          subcategoryProvider: subcategoryProvider,
          databaseHelper: databaseHelper,
          notificationBridge: notificationBridge,
          clock: () => now,
        );
        await timer.initialize();
        expect(timer.isRunning, isTrue);
        expect(timer.elapsedSeconds, 20 * 60);
        expect(
          notificationBridge.events.last,
          const _NotificationEvent.sync(
            subcategoryName: 'Chess',
            elapsedSeconds: 20 * 60,
            isRunning: true,
          ),
        );

        await timer.pause();
        timerRows = await database.query(
          MotionDbTables.activeTimerSession,
        );
        expect(
          timerRows.single[MotionDbColumns.timerStatus],
          ActivityTimerStatus.paused.name,
        );
        expect(
          timerRows.single[MotionDbColumns.currentSegmentStartedAtEpochMs],
          isNull,
        );
        expect(notificationBridge.events.last.isRunning, isFalse);

        now = DateTime(2026, 7, 19, 10);
        expect(timer.elapsedSeconds, 20 * 60);

        await timer.resume();
        timerRows = await database.query(
          MotionDbTables.activeTimerSession,
        );
        expect(
          timerRows.single[MotionDbColumns.timerStatus],
          ActivityTimerStatus.running.name,
        );
        expect(
          timerRows.single[MotionDbColumns.currentSegmentStartedAtEpochMs],
          now.millisecondsSinceEpoch,
        );
        expect(notificationBridge.events.last.isRunning, isTrue);

        now = DateTime(2026, 7, 19, 10, 15);
        await expectLater(
          timer.start(
            mainCategoryName: MotionCategories.education,
            subcategoryName: 'Studied/Revised',
          ),
          throwsA(isA<ActivityTimerAlreadyRunning>()),
        );

        final result = await timer.finish();

        expect(result.totalSeconds, 35 * 60);
        expect(result.entries, hasLength(1));
        expect(result.entries.single.timeSpent, 35.0);
        expect(timer.hasActiveTimer, isFalse);

        final subcategoryRows = await database.query(
          MotionDbTables.subcategory,
        );
        expect(subcategoryRows, hasLength(1));
        expect(
          subcategoryRows.single[MotionDbColumns.date],
          '2026-07-19',
        );
        expect(
          subcategoryRows.single[MotionDbColumns.subcategoryName],
          'Chess',
        );
        expect(
          subcategoryRows.single[MotionDbColumns.timeSpent],
          35.0,
        );

        final mainCategoryRows = await database.query(
          MotionDbTables.mainCategory,
        );
        expect(mainCategoryRows, hasLength(1));
        expect(mainCategoryRows.single[MotionDbColumns.skills], 35.0);

        final experienceRows = await database.query(
          MotionDbTables.experiencePoints,
        );
        expect(experienceRows, hasLength(1));
        expect(experienceRows.single[MotionDbColumns.skillsXp], 2);
        expect(
          experienceRows.single[MotionDbColumns.accountabilityBonusXp],
          0,
        );

        timerRows = await database.query(
          MotionDbTables.activeTimerSession,
        );
        expect(timerRows, isEmpty);
        expect(revisions.subcategoryRevision, 1);
        expect(revisions.mainCategoryRevision, 1);
        expect(revisions.experiencePointRevision, 1);
        expect(notificationBridge.events.last.type, 'stop');
      },
    );

    test('notification failures never prevent timer persistence', () async {
      notificationBridge.throwOnRequestPermission = true;
      notificationBridge.throwOnSync = true;

      await timer.start(
        mainCategoryName: MotionCategories.skills,
        subcategoryName: 'Chess',
      );

      expect(timer.hasActiveTimer, isTrue);
      expect(timer.notificationPermissionGranted, isFalse);
      final timerRows = await database.query(
        MotionDbTables.activeTimerSession,
      );
      expect(timerRows, hasLength(1));
      expect(
        timerRows.single[MotionDbColumns.subcategoryName],
        'Chess',
      );
    });

    test('timed sessions pause, alert once, persist, and continue overtime',
        () async {
      await timer.start(
        mainCategoryName: MotionCategories.skills,
        subcategoryName: 'Chess',
        targetSeconds: 60 * 60,
      );
      expect(notificationBridge.lastPermissionRequiredExactAlarm, isTrue);

      var timerRows = await database.query(MotionDbTables.activeTimerSession);
      expect(
        timerRows.single[MotionDbColumns.timerTargetSeconds],
        60 * 60,
      );
      expect(
        timerRows.single[MotionDbColumns.timerTargetAlertTriggered],
        0,
      );

      now = DateTime(2026, 7, 19, 9, 20);
      await timer.pause();
      now = DateTime(2026, 7, 19, 12);
      expect(timer.remainingTargetSeconds, 40 * 60);

      await timer.resume();
      now = DateTime(2026, 7, 19, 12, 40);
      timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _flushAsyncWork();

      expect(timer.hasReachedTarget, isTrue);
      expect(timer.hasPendingTargetReachedEvent, isTrue);
      expect(timer.consumeTargetReachedEvent()?.subcategoryName, 'Chess');
      expect(timer.hasPendingTargetReachedEvent, isFalse);
      expect(
        notificationBridge.events.where((event) => event.type == 'target'),
        hasLength(1),
      );

      timerRows = await database.query(MotionDbTables.activeTimerSession);
      expect(
        timerRows.single[MotionDbColumns.timerTargetAlertTriggered],
        1,
      );

      now = DateTime(2026, 7, 19, 12, 45);
      timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _flushAsyncWork();
      expect(timer.overtimeSeconds, 5 * 60);
      expect(
        notificationBridge.events.where((event) => event.type == 'target'),
        hasLength(1),
      );

      final result = await timer.finish();
      expect(result.totalSeconds, 65 * 60);
      expect(result.entries.single.timeSpent, 65.0);
    });

    test('rejects timer targets longer than 24 hours', () async {
      await expectLater(
        timer.start(
          mainCategoryName: MotionCategories.skills,
          subcategoryName: 'Chess',
          targetSeconds: ActivityTimerProvider.maximumTargetSeconds + 1,
        ),
        throwsA(isA<StateError>()),
      );
      expect(timer.hasActiveTimer, isFalse);
    });

    test('dismisses the native target alert on user acknowledgement', () async {
      await timer.dismissTargetAlert();

      expect(
        notificationBridge.events.where((event) => event.type == 'dismiss'),
        hasLength(1),
      );
    });

    test('a delayed target alert cannot restore a finished timer', () async {
      final alertGate = Completer<void>();
      notificationBridge.targetAlertGate = alertGate;
      await timer.start(
        mainCategoryName: MotionCategories.skills,
        subcategoryName: 'Chess',
        targetSeconds: 60,
      );

      now = DateTime(2026, 7, 19, 9, 1);
      timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _flushAsyncWork();
      expect(
        notificationBridge.events.where((event) => event.type == 'target'),
        hasLength(1),
      );

      await timer.finish();
      expect(
        await database.query(MotionDbTables.activeTimerSession),
        isEmpty,
      );

      alertGate.complete();
      await _flushAsyncWork();
      expect(
        await database.query(MotionDbTables.activeTimerSession),
        isEmpty,
      );
    });

    test('failed daily-limit validation keeps the timer available', () async {
      await databaseHelper.insertSubcategory(Subcategories(
        date: '2026-07-19',
        mainCategoryName: MotionCategories.skills,
        subcategoryName: 'Chess',
        timeSpent: 1400,
        currentLoggedInUser: 'user-1',
      ));
      await timer.start(
        mainCategoryName: MotionCategories.skills,
        subcategoryName: 'Chess',
      );
      now = DateTime(2026, 7, 19, 10);

      await expectLater(
        timer.finish(),
        throwsA(isA<DailyTimeLimitExceeded>()),
      );

      expect(timer.hasActiveTimer, isTrue);
      expect(
        await database.query(MotionDbTables.activeTimerSession),
        hasLength(1),
      );
      expect(
        await database.query(MotionDbTables.subcategory),
        hasLength(1),
      );
    });
  });
}

class _FakeActivityTimerNotificationBridge
    implements ActivityTimerNotificationBridge {
  final List<_NotificationEvent> events = [];
  bool throwOnRequestPermission = false;
  bool throwOnSync = false;
  bool? lastPermissionRequiredExactAlarm;
  Completer<void>? targetAlertGate;

  @override
  Future<bool> requestPermission({required bool requiresExactAlarm}) async {
    if (throwOnRequestPermission) throw StateError('Permission unavailable');
    lastPermissionRequiredExactAlarm = requiresExactAlarm;
    events.add(const _NotificationEvent.permission());
    return true;
  }

  @override
  Future<void> dismissTargetAlert() async {
    events.add(const _NotificationEvent.dismiss());
  }

  @override
  Future<void> sync({
    required ActivityTimerSession session,
    required int elapsedSeconds,
  }) async {
    if (throwOnSync) throw StateError('Notification unavailable');
    events.add(_NotificationEvent.sync(
      subcategoryName: session.subcategoryName,
      elapsedSeconds: elapsedSeconds,
      isRunning: session.isRunning,
    ));
  }

  @override
  Future<void> targetReached({
    required ActivityTimerSession session,
    required int elapsedSeconds,
  }) async {
    events.add(_NotificationEvent.target(
      subcategoryName: session.subcategoryName,
      elapsedSeconds: elapsedSeconds,
      isRunning: session.isRunning,
    ));
    await targetAlertGate?.future;
  }

  @override
  Future<void> stop() async {
    events.add(const _NotificationEvent.stop());
  }
}

class _NotificationEvent {
  final String type;
  final String? subcategoryName;
  final int? elapsedSeconds;
  final bool? isRunning;

  const _NotificationEvent.permission()
      : type = 'permission',
        subcategoryName = null,
        elapsedSeconds = null,
        isRunning = null;

  const _NotificationEvent.sync({
    required this.subcategoryName,
    required this.elapsedSeconds,
    required this.isRunning,
  }) : type = 'sync';

  const _NotificationEvent.stop()
      : type = 'stop',
        subcategoryName = null,
        elapsedSeconds = null,
        isRunning = null;

  const _NotificationEvent.target({
    required this.subcategoryName,
    required this.elapsedSeconds,
    required this.isRunning,
  }) : type = 'target';

  const _NotificationEvent.dismiss()
      : type = 'dismiss',
        subcategoryName = null,
        elapsedSeconds = null,
        isRunning = null;

  @override
  bool operator ==(Object other) {
    return other is _NotificationEvent &&
        type == other.type &&
        subcategoryName == other.subcategoryName &&
        elapsedSeconds == other.elapsedSeconds &&
        isRunning == other.isRunning;
  }

  @override
  int get hashCode => Object.hash(
        type,
        subcategoryName,
        elapsedSeconds,
        isRunning,
      );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
