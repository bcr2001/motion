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
    required this.emailMatchesMotionAccount,
  });

  final String email;
  final String folderName;
  final int fileCount;
  final bool emailMatchesMotionAccount;
}

class GoogleDriveBackupService {
  GoogleDriveBackupService({
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const [drive.DriveApi.driveFileScope],
            );

  static const String backupFolderName = 'Motion Backups';

  final GoogleSignIn _googleSignIn;

  Future<GoogleDriveBackupResult> uploadBackupFiles({
    required List<MotionCsvBackupFile> files,
    String? expectedEmail,
  }) async {
    if (files.isEmpty) {
      throw StateError('There are no backup files to upload.');
    }

    try {
      final account =
          await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
      if (account == null) {
        throw StateError('Google Drive backup was cancelled.');
      }

      final client = await _googleSignIn.authenticatedClient();
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

        final normalizedExpectedEmail = expectedEmail?.trim().toLowerCase();
        final actualEmail = account.email.trim();
        return GoogleDriveBackupResult(
          email: actualEmail,
          folderName: backupFolderName,
          fileCount: files.length,
          emailMatchesMotionAccount: normalizedExpectedEmail == null ||
              normalizedExpectedEmail.isEmpty ||
              normalizedExpectedEmail == actualEmail.toLowerCase(),
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
      throw StateError('Motion could not create the Google Drive backup folder.');
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
}
