import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:motion/motion_core/mc_csv/csv_data_transfer.dart';

class GoogleDriveBackupResult {
  const GoogleDriveBackupResult({
    required this.email,
    required this.folderName,
    required this.fileCount,
  });

  final String email;
  final String folderName;
  final int fileCount;
}

abstract interface class GoogleDriveAccountSession {
  Future<String?> signInSilently();

  Future<String?> signIn();

  Future<void> signOut();

  Future<http.Client?> authenticatedClient();
}

class GoogleSignInDriveAccountSession implements GoogleDriveAccountSession {
  GoogleSignInDriveAccountSession({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const [drive.DriveApi.driveFileScope],
            );

  final GoogleSignIn _googleSignIn;

  @override
  Future<String?> signInSilently() async {
    return (await _googleSignIn.signInSilently())?.email;
  }

  @override
  Future<String?> signIn() async {
    return (await _googleSignIn.signIn())?.email;
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();

  @override
  Future<http.Client?> authenticatedClient() {
    return _googleSignIn.authenticatedClient();
  }
}

class GoogleDriveBackupService {
  GoogleDriveBackupService({
    GoogleDriveAccountSession? accountSession,
  }) : _accountSession = accountSession ?? GoogleSignInDriveAccountSession();

  static const String backupFolderName = 'Motion Backups';

  final GoogleDriveAccountSession _accountSession;

  Future<GoogleDriveBackupResult> uploadBackupFiles({
    required List<MotionCsvBackupFile> files,
    required String expectedEmail,
    bool allowInteractiveSignIn = true,
  }) async {
    if (files.isEmpty) {
      throw StateError('There are no backup files to upload.');
    }

    final normalizedExpectedEmail = expectedEmail.trim().toLowerCase();
    if (normalizedExpectedEmail.isEmpty) {
      throw StateError(
        'Motion could not verify the email for the signed-in account. No files were uploaded.',
      );
    }

    try {
      var driveEmail = await _accountSession.signInSilently();
      if (driveEmail == null && allowInteractiveSignIn) {
        driveEmail = await _accountSession.signIn();
      }
      if (driveEmail == null) {
        throw StateError(
          allowInteractiveSignIn
              ? 'Google Drive backup was cancelled.'
              : 'Google Drive is not connected. Export to Google Drive manually once, then automatic backups can continue.',
        );
      }

      if (driveEmail.trim().toLowerCase() != normalizedExpectedEmail &&
          allowInteractiveSignIn) {
        await _accountSession.signOut();
        driveEmail = await _accountSession.signIn();
      }

      if (driveEmail == null ||
          driveEmail.trim().toLowerCase() != normalizedExpectedEmail) {
        if (allowInteractiveSignIn) {
          await _accountSession.signOut();
        }
        throw StateError(
          'Google Drive must use the same email as your Motion account ($expectedEmail). No files were uploaded.',
        );
      }

      final client = await _accountSession.authenticatedClient();
      if (client == null) {
        throw StateError(
          'Motion could not connect to Google Drive. Please try signing in again.',
        );
      }

      try {
        final driveApi = drive.DriveApi(client);
        final folderId = await _findOrCreateBackupFolder(driveApi);

        for (final file in files) {
          await _createOrReplaceFile(
            driveApi: driveApi,
            folderId: folderId,
            file: file,
          );
        }

        return GoogleDriveBackupResult(
          email: driveEmail.trim(),
          folderName: backupFolderName,
          fileCount: files.length,
        );
      } finally {
        client.close();
      }
    } on SocketException {
      throw StateError(
        'No internet connection. Please connect to the internet and try Google Drive backup again.',
      );
    } on http.ClientException catch (error) {
      if (_isNetworkClientError(error)) {
        throw StateError(
          'No internet connection. Please connect to the internet and try Google Drive backup again.',
        );
      }
      rethrow;
    } catch (error) {
      if (_isDriveStorageFull(error)) {
        throw StateError(
          'Google Drive is full. Free up space in Google Drive, then try backup again.',
        );
      }
      rethrow;
    }
  }

  Future<String> _findOrCreateBackupFolder(drive.DriveApi driveApi) async {
    final existingFolders = await driveApi.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' "
          "and name = '${_escapeQueryValue(backupFolderName)}' "
          "and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
      pageSize: 1,
    );

    final existingFolderId = _firstFileId(existingFolders.files);
    if (existingFolderId != null) return existingFolderId;

    final folderMetadata = drive.File()
      ..name = backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final createdFolder = await driveApi.files.create(
      folderMetadata,
      $fields: 'id',
    );

    final folderId = createdFolder.id;
    if (folderId == null || folderId.isEmpty) {
      throw StateError(
          'Motion could not create the Google Drive backup folder.');
    }
    return folderId;
  }

  Future<void> _createOrReplaceFile({
    required drive.DriveApi driveApi,
    required String folderId,
    required MotionCsvBackupFile file,
  }) async {
    final existingFiles = await driveApi.files.list(
      q: "name = '${_escapeQueryValue(file.fileName)}' "
          "and '$folderId' in parents "
          "and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
      pageSize: 1,
    );
    final fileId = _firstFileId(existingFiles.files);

    final bytes = utf8.encode(file.content);
    final media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'text/csv',
    );
    final metadata = drive.File()
      ..name = file.fileName
      ..mimeType = 'text/csv';

    if (fileId == null) {
      metadata.parents = [folderId];
      await driveApi.files.create(
        metadata,
        uploadMedia: media,
        $fields: 'id',
      );
    } else {
      await driveApi.files.update(
        metadata,
        fileId,
        uploadMedia: media,
        $fields: 'id',
      );
    }
  }

  String _escapeQueryValue(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }

  String? _firstFileId(List<drive.File>? files) {
    if (files == null) return null;
    for (final file in files) {
      final id = file.id;
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  bool _isNetworkClientError(http.ClientException error) {
    final message = error.message.toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection failed') ||
        message.contains('network is unreachable');
  }

  bool _isDriveStorageFull(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('storagequotaexceeded') ||
        message.contains('storage quota') ||
        message.contains('insufficient storage') ||
        message.contains('drive is full') ||
        message.contains('quota exceeded');
  }
}
