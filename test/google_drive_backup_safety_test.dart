import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:motion/motion_core/mc_cloud/google_drive_backup_service.dart';
import 'package:motion/motion_core/mc_csv/csv_data_transfer.dart';
import 'package:motion/motion_core/motion_providers/cloud_backup_pvd/auto_drive_backup_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Drive backup account safety', () {
    test('rejects a mismatched Drive account before requesting a client',
        () async {
      final session = _FakeDriveAccountSession(
        silentEmail: 'different@example.com',
      );
      final service = GoogleDriveBackupService(accountSession: session);

      await expectLater(
        service.uploadBackupFiles(
          files: const [
            MotionCsvBackupFile(
              fileName: 'subcategory.csv',
              content: 'date,timeSpent\n2026-08-08,10',
            ),
          ],
          expectedEmail: 'motion@example.com',
          allowInteractiveSignIn: false,
        ),
        throwsA(
          isA<StateError>()
              .having(
                (error) => error.message,
                'message',
                contains('same email as your Motion account'),
              )
              .having(
                (error) => error.message,
                'upload result',
                contains('No files were uploaded'),
              ),
        ),
      );

      expect(session.authenticatedClientCalls, 0);
      expect(session.interactiveSignInCalls, 0);
    });

    test('rejects a mismatched account selected during manual sign-in',
        () async {
      final session = _FakeDriveAccountSession(
        silentEmail: 'previous@example.com',
        interactiveEmail: 'different@example.com',
      );
      final service = GoogleDriveBackupService(accountSession: session);

      await expectLater(
        service.uploadBackupFiles(
          files: const [
            MotionCsvBackupFile(
              fileName: 'subcategory.csv',
              content: 'date,timeSpent\n2026-08-08,10',
            ),
          ],
          expectedEmail: 'motion@example.com',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('same email as your Motion account'),
          ),
        ),
      );

      expect(session.interactiveSignInCalls, 1);
      expect(session.signOutCalls, 2);
      expect(session.authenticatedClientCalls, 0);
    });

    test('does not inherit automatic backup settings across Motion users',
        () async {
      final today = MotionDateUtils.todayIso();
      SharedPreferences.setMockInitialValues({
        'autoDriveBackupEnabled': true,
        'autoDriveBackupEnabled.user-a': true,
        'autoDriveBackupLastSuccessDate.user-a': today,
        'autoDriveBackupLastStatus.user-a': 'success',
        'autoDriveBackupLastMessage.user-a': 'User A backup is current.',
      });

      final userProvider = UserUidProvider(
        initialUserUid: 'user-a',
        isInitialized: true,
      );
      final backupProvider = AutoDriveBackupProvider(
        userUidProvider: userProvider,
        driveBackupService: GoogleDriveBackupService(
          accountSession: _FakeDriveAccountSession(),
        ),
        motionEmailForUser: (uid) => '$uid@example.com',
      );
      addTearDown(() {
        backupProvider.dispose();
        userProvider.dispose();
      });

      await backupProvider.initialize();
      await _flushAsyncWork();
      expect(backupProvider.isEnabled, isTrue);
      expect(backupProvider.message, 'User A backup is current.');

      userProvider.setUserUid('user-b');
      await _flushAsyncWork();
      expect(backupProvider.isEnabled, isFalse);
      expect(
        backupProvider.message,
        'Automatic Google Drive backup is off.',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('autoDriveBackupEnabled'), isNull);
      expect(prefs.getBool('autoDriveBackupEnabled.user-a'), isTrue);
      expect(prefs.getBool('autoDriveBackupEnabled.user-b'), isNull);

      userProvider.setUserUid('user-a');
      await _flushAsyncWork();
      expect(backupProvider.isEnabled, isTrue);
      expect(backupProvider.message, 'User A backup is current.');
    });

    test('an in-flight backup remains bound to the user that started it',
        () async {
      SharedPreferences.setMockInitialValues({});
      final userProvider = UserUidProvider(
        initialUserUid: 'user-a',
        isInitialized: true,
      );
      final csvTransfer = _StaticCsvDataTransfer();
      final driveService = _BlockingDriveBackupService();
      final backupProvider = AutoDriveBackupProvider(
        userUidProvider: userProvider,
        csvTransfer: csvTransfer,
        driveBackupService: driveService,
        motionEmailForUser: (uid) => '$uid@example.com',
      );
      addTearDown(() {
        backupProvider.dispose();
        userProvider.dispose();
      });

      await backupProvider.initialize();
      await backupProvider.setEnabled(true);
      await driveService.started.future;

      userProvider.setUserUid('user-b');
      await _flushAsyncWork();
      expect(backupProvider.isEnabled, isFalse);

      driveService.complete();
      await _flushAsyncWork();

      expect(csvTransfer.requestedUsers, ['user-a']);
      expect(driveService.expectedEmails, ['user-a@example.com']);
      expect(backupProvider.isEnabled, isFalse);
      expect(
        backupProvider.message,
        'Automatic Google Drive backup is off.',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('autoDriveBackupLastStatus.user-b'), isNull);
      expect(prefs.getString('autoDriveBackupLastMessage.user-b'), isNull);
    });
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeDriveAccountSession implements GoogleDriveAccountSession {
  _FakeDriveAccountSession({
    this.silentEmail,
    this.interactiveEmail,
  });

  final String? silentEmail;
  final String? interactiveEmail;
  int interactiveSignInCalls = 0;
  int authenticatedClientCalls = 0;
  int signOutCalls = 0;

  @override
  Future<http.Client?> authenticatedClient() async {
    authenticatedClientCalls++;
    return null;
  }

  @override
  Future<String?> signIn() async {
    interactiveSignInCalls++;
    return interactiveEmail;
  }

  @override
  Future<String?> signInSilently() async => silentEmail;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

class _StaticCsvDataTransfer extends MotionCsvDataTransfer {
  final List<String> requestedUsers = [];

  @override
  Future<List<MotionCsvBackupFile>> backupFiles({
    required String currentUser,
  }) async {
    requestedUsers.add(currentUser);
    return const [
      MotionCsvBackupFile(
        fileName: 'subcategory.csv',
        content: 'date,timeSpent\n2026-08-08,10',
      ),
    ];
  }
}

class _BlockingDriveBackupService extends GoogleDriveBackupService {
  _BlockingDriveBackupService()
      : super(accountSession: _FakeDriveAccountSession());

  final Completer<void> started = Completer<void>();
  final Completer<GoogleDriveBackupResult> _result =
      Completer<GoogleDriveBackupResult>();
  final List<String> expectedEmails = [];

  @override
  Future<GoogleDriveBackupResult> uploadBackupFiles({
    required List<MotionCsvBackupFile> files,
    required String expectedEmail,
    bool allowInteractiveSignIn = true,
  }) {
    expectedEmails.add(expectedEmail);
    if (!started.isCompleted) started.complete();
    return _result.future;
  }

  void complete() {
    _result.complete(
      const GoogleDriveBackupResult(
        email: 'user-a@example.com',
        folderName: GoogleDriveBackupService.backupFolderName,
        fileCount: 1,
      ),
    );
  }
}
