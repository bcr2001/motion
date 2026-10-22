import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:motion/motion_core/mc_cloud/google_drive_backup_service.dart';
import 'package:motion/motion_core/motion_providers/cloud_backup_pvd/auto_drive_backup_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_screens/ms_settings/data_transfer_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('Backup Health fits a narrow screen in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'autoDriveBackupEnabled.user-a': true,
        'autoDriveBackupLastSuccessDate.user-a': '2026-10-15',
        'autoDriveBackupLastSuccessAt.user-a': '2026-10-15T20:00:00.000',
        'autoDriveBackupLastStatus.user-a': 'success',
        'autoDriveBackupLastMessage.user-a': 'Backup complete.',
        'autoDriveBackupDriveAccountEmail.user-a':
            'a.long.motion.account@example.com',
        'autoDriveBackupLastSizeBytes.user-a': 15360,
      });
      final userProvider = UserUidProvider(
        initialUserUid: 'user-a',
        isInitialized: true,
      );
      final backupProvider = AutoDriveBackupProvider(
        userUidProvider: userProvider,
        driveBackupService: GoogleDriveBackupService(
          accountSession: _NoopDriveSession(),
        ),
        motionEmailForUser: (_) => 'a.long.motion.account@example.com',
        now: () => DateTime(2026, 10, 15, 20, 30),
      );
      addTearDown(() {
        backupProvider.dispose();
        userProvider.dispose();
      });
      await backupProvider.initialize();

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
              child: BackupHealthCard(
                backup: backupProvider,
                onChanged: (_) {},
                onRunNow: () {},
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Backup Health'), findsOneWidget);
      expect(find.text('Backup is healthy'), findsOneWidget);
      expect(find.text('Connected Drive account'), findsOneWidget);
      expect(find.text('15.0 KB'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _NoopDriveSession implements GoogleDriveAccountSession {
  @override
  Future<http.Client?> authenticatedClient() async => null;

  @override
  Future<String?> signIn() async => null;

  @override
  Future<String?> signInSilently() async => null;

  @override
  Future<void> signOut() async {}
}
