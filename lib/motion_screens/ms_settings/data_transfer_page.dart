import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_cloud/google_drive_backup_service.dart';
import 'package:motion/motion_core/mc_csv/csv_data_transfer.dart';
import 'package:motion/motion_core/mc_csv/motion_backup_restore.dart';
import 'package:motion/motion_core/motion_providers/cloud_backup_pvd/auto_drive_backup_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_providers/timer_pvd/activity_timer_pvd.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

part 'data_transfer_widgets.dart';

class DataTransferPage extends StatefulWidget {
  const DataTransferPage({super.key});

  @override
  State<DataTransferPage> createState() => _DataTransferPageState();
}

class _DataTransferPageState extends State<DataTransferPage> {
  final MotionCsvDataTransfer _csvTransfer = MotionCsvDataTransfer();
  final MotionBackupRestoreService _backupRestoreService =
      MotionBackupRestoreService();
  final GoogleDriveBackupService _driveBackupService =
      GoogleDriveBackupService();
  bool _isBusy = false;
  String _busyTitle = 'Working';
  String _busyDetail = 'Please wait...';
  int _summaryRefreshKey = 0;

  Future<void> _runWithFeedback(
    String successMessage,
    Future<String> Function(String currentUser) action, {
    String busyTitle = 'Working',
    String busyDetail = 'Please wait...',
    String failureTitle = 'Transfer Failed',
  }) async {
    final currentUser = context.read<UserUidProvider>().userUid;
    if (currentUser == null) {
      await _showTransferResultDialog(
        title: 'User Loading',
        message: 'Your account is still loading. Please try again.',
        icon: Icons.person_search_rounded,
        isError: true,
      );
      return;
    }

    _startBusy(title: busyTitle, detail: busyDetail);
    var title = 'Complete';
    var message = '';
    var icon = Icons.check_circle_outline_rounded;
    var isError = false;

    try {
      final detail = await action(currentUser);
      if (!mounted) return;
      if (detail.startsWith('cancelled')) {
        title = 'Cancelled';
        message = detail;
        icon = Icons.info_outline_rounded;
      } else {
        message = '$successMessage $detail';
      }
    } catch (error) {
      if (!mounted) return;
      title = failureTitle;
      if (error is StateError) {
        message = error.message;
      } else if (error is UnsupportedError) {
        message = error.message?.toString() ?? '$error';
      } else {
        message = '$error';
      }
      icon = Icons.error_outline_rounded;
      isError = true;
    } finally {
      _stopBusy();
    }

    if (!mounted) return;
    await _showTransferResultDialog(
      title: title,
      message: message,
      icon: icon,
      isError: isError,
    );
  }

  void _startBusy({
    required String title,
    required String detail,
  }) {
    if (!mounted) return;
    setState(() {
      _isBusy = true;
      _busyTitle = title;
      _busyDetail = detail;
    });
  }

  void _stopBusy() {
    if (!mounted) return;
    setState(() {
      _isBusy = false;
    });
  }

  void _refreshDataSummary() {
    if (!mounted) return;
    setState(() => _summaryRefreshKey++);
  }

  Future<MotionDataSummary> _loadDataSummary(
    String currentUser,
    int refreshKey,
  ) {
    return _csvTransfer.dataSummaryForUser(currentUser: currentUser);
  }

  Future<String> _createAutomaticBackup(String currentUser) async {
    try {
      final location = await _csvTransfer.exportBackupToDownloads(
        currentUser: currentUser,
      );
      return 'Backup saved to $location.';
    } on StateError {
      return 'No existing data was available to back up.';
    }
  }

  Future<void> _exportCsv() async {
    await _runWithFeedback('Exported CSV files to', (currentUser) async {
      try {
        return await _csvTransfer.exportAllToDownloads(
          currentUser: currentUser,
        );
      } on StateError {
        rethrow;
      } catch (_) {
        final selectedDirectory = await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory == null) {
          return 'cancelled. No folder was selected.';
        }

        return _csvTransfer.exportAllToDirectory(
          currentUser: currentUser,
          directoryPath: selectedDirectory,
        );
      }
    }, busyTitle: 'Exporting CSV Files', busyDetail: 'Preparing your data...');
  }

  Future<void> _showExportBackupOptions() async {
    final selectedOption = await showDialog<_BackupLocationOption>(
      context: context,
      builder: (dialogContext) {
        return _BackupLocationOptionsDialog(
          mode: _BackupLocationMode.export,
          onDevice: () =>
              Navigator.of(dialogContext).pop(_BackupLocationOption.device),
          onGoogleDrive: () => Navigator.of(dialogContext)
              .pop(_BackupLocationOption.googleDrive),
          onCancel: () =>
              Navigator.of(dialogContext).pop(_BackupLocationOption.cancel),
        );
      },
    );

    switch (selectedOption) {
      case _BackupLocationOption.device:
        await _exportCsv();
        break;
      case _BackupLocationOption.googleDrive:
        await _exportCsvToGoogleDrive();
        break;
      case _BackupLocationOption.cancel:
      case null:
        break;
    }
  }

  Future<void> _showRestoreBackupOptions() async {
    final selectedOption = await showDialog<_BackupLocationOption>(
      context: context,
      builder: (dialogContext) {
        return _BackupLocationOptionsDialog(
          mode: _BackupLocationMode.restore,
          onDevice: () =>
              Navigator.of(dialogContext).pop(_BackupLocationOption.device),
          onGoogleDrive: () => Navigator.of(dialogContext)
              .pop(_BackupLocationOption.googleDrive),
          onCancel: () =>
              Navigator.of(dialogContext).pop(_BackupLocationOption.cancel),
        );
      },
    );

    switch (selectedOption) {
      case _BackupLocationOption.device:
        await _restoreBackupFromDevice();
        break;
      case _BackupLocationOption.googleDrive:
        await _restoreBackupFromGoogleDrive();
        break;
      case _BackupLocationOption.cancel:
      case null:
        break;
    }
  }

  Future<void> _restoreBackupFromDevice() async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (selection == null) return;

      final files = <MotionCsvBackupFile>[];
      for (final selectedFile in selection.files) {
        final bytes = selectedFile.bytes ??
            (selectedFile.path == null
                ? null
                : await File(selectedFile.path!).readAsBytes());
        if (bytes == null) {
          throw StateError('Motion could not read ${selectedFile.name}.');
        }
        files.add(
          MotionCsvBackupFile(
            fileName: selectedFile.name,
            content: utf8.decode(bytes),
          ),
        );
      }
      await _prepareBackupRestore(files, source: 'your device');
    } catch (error) {
      if (!mounted) return;
      await _showTransferResultDialog(
        title: 'Restore Failed',
        message: error is StateError ? error.message : '$error',
        icon: Icons.restore_page_rounded,
        isError: true,
      );
    }
  }

  Future<void> _restoreBackupFromGoogleDrive() async {
    final currentUser = context.read<UserUidProvider>().userUid;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final motionEmail =
        firebaseUser?.uid == currentUser ? firebaseUser?.email?.trim() : null;
    if (currentUser == null || motionEmail == null || motionEmail.isEmpty) {
      await _showTransferResultDialog(
        title: 'Account Unavailable',
        message: 'Motion could not verify your signed-in account email.',
        icon: Icons.person_search_rounded,
        isError: true,
      );
      return;
    }

    _startBusy(
      title: 'Loading Google Drive Backup',
      detail: 'Downloading your latest Motion backup...',
    );
    try {
      final result = await _driveBackupService.downloadBackupFiles(
        expectedEmail: motionEmail,
      );
      if (!mounted) return;
      _stopBusy();
      await _prepareBackupRestore(
        result.files,
        source: '${result.folderName} in ${result.email}',
      );
    } catch (error) {
      _stopBusy();
      if (!mounted) return;
      await _showTransferResultDialog(
        title: 'Restore Failed',
        message: error is StateError ? error.message : '$error',
        icon: Icons.cloud_off_rounded,
        isError: true,
      );
    }
  }

  Future<void> _prepareBackupRestore(
    List<MotionCsvBackupFile> files, {
    required String source,
  }) async {
    final currentUser = context.read<UserUidProvider>().userUid;
    if (currentUser == null) {
      throw StateError('Your Motion account is still loading.');
    }

    final backup = _backupRestoreService.validateBackup(
      files: files,
      currentUser: currentUser,
    );
    final preview = backup.preview;
    final dateRange = preview.firstTrackedDate == null
        ? 'No tracked dates'
        : preview.firstTrackedDate == preview.lastTrackedDate
            ? preview.firstTrackedDate!
            : '${preview.firstTrackedDate} - ${preview.lastTrackedDate}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _DataTransferDialog(
          icon: Icons.restore_rounded,
          iconColor: AppColor.blueMainColor,
          title: 'Restore Motion Backup?',
          message: 'Source: $source\n'
              'Tracked dates: $dateRange\n'
              'Tracking rows: ${preview.trackingRows}\n'
              'Assigned subcategories: ${preview.assignedRows}\n\n'
              'This replaces the local Motion data for this account. '
              'Your current data will be backed up to Downloads first.',
          primaryLabel: 'Restore Backup',
          secondaryLabel: 'Cancel',
          onPrimary: () => Navigator.of(dialogContext).pop(true),
          onSecondary: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final timerProvider = context.read<ActivityTimerProvider>();
    await _runWithFeedback(
      'Restore complete:',
      (activeUser) async {
        if (activeUser != backup.currentUser) {
          throw StateError(
            'The signed-in Motion account changed. Restore was cancelled.',
          );
        }

        _updateBusyDetail('Backing up your current local data...');
        final currentSummary = await _csvTransfer.dataSummaryForUser(
          currentUser: activeUser,
        );
        var safetyBackupMessage =
            'There was no previous local data to back up.';
        if (currentSummary.hasExportableData) {
          safetyBackupMessage = await _createAutomaticBackup(activeUser);
        }

        _updateBusyDetail('Validating and rebuilding Motion data...');
        await timerProvider.discard();
        final result = await _backupRestoreService.restoreBackup(
          backup: backup,
          currentUser: activeUser,
        );

        if (!mounted) return '${result.trackingRows} tracking row(s).';
        context
            .read<SubcategoryTrackerDatabaseProvider>()
            .refreshAllTrackingData();
        await context.read<AssignerMainProvider>().getAllUserItems();
        _refreshDataSummary();

        return '${result.trackingRows} tracking, '
            '${result.dailyTotalRows} daily total, '
            '${result.experiencePointRows} XP, and '
            '${result.assignedRows} assigned row(s) restored.\n'
            '$safetyBackupMessage';
      },
      busyTitle: 'Restoring Motion Backup',
      busyDetail: 'Preparing the restore...',
      failureTitle: 'Restore Failed',
    );
  }

  Future<void> _exportCsvToGoogleDrive() async {
    await _runWithFeedback(
      'Google Drive backup complete:',
      (currentUser) async {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        final motionEmail = firebaseUser?.uid == currentUser
            ? firebaseUser?.email?.trim()
            : null;
        if (motionEmail == null || motionEmail.isEmpty) {
          throw StateError(
            'Motion could not verify the email for your signed-in account. No files were uploaded.',
          );
        }

        _updateBusyDetail('Preparing backup files from your database...');
        final backupFiles = await _csvTransfer.backupFiles(
          currentUser: currentUser,
        );

        _updateBusyDetail('Connecting to Google Drive...');
        final result = await _driveBackupService.uploadBackupFiles(
          files: backupFiles,
          expectedEmail: motionEmail,
        );
        if (mounted) {
          await context.read<AutoDriveBackupProvider>().recordSuccessfulBackup(
                currentUser: currentUser,
                fileCount: result.fileCount,
                driveAccountEmail: result.email,
                totalBytes: result.totalBytes,
              );
        }

        return '${result.fileCount} file(s) saved to '
            '${result.folderName} in ${result.email}.';
      },
      busyTitle: 'Backing Up To Google Drive',
      busyDetail: 'Preparing your data...',
    );
  }

  Future<bool> _confirmDeleteAllData() async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _DataTransferDialog(
          icon: Icons.delete_forever_rounded,
          iconColor: Colors.redAccent,
          title: 'Delete All Data?',
          message:
              'This removes your local tracking history, main category totals, XP records, assigned subcategories, and streak settings for this account. Motion will create an automatic backup first when data exists. This does not delete your Firebase account.',
          primaryLabel: 'Continue',
          secondaryLabel: 'Cancel',
          onPrimary: () => Navigator.of(dialogContext).pop(true),
          onSecondary: () => Navigator.of(dialogContext).pop(false),
          isDangerAction: true,
        );
      },
    );
    if (firstConfirm != true) return false;
    if (!mounted) return false;

    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _DataTransferDialog(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.redAccent,
          title: 'Delete Permanently?',
          message:
              'This cannot be undone from inside the app. Continue only if you are sure you want to clear this account on this device.',
          primaryLabel: 'Delete Data',
          secondaryLabel: 'Cancel',
          onPrimary: () => Navigator.of(dialogContext).pop(true),
          onSecondary: () => Navigator.of(dialogContext).pop(false),
          isDangerAction: true,
        );
      },
    );

    return finalConfirm ?? false;
  }

  Future<void> _showTransferResultDialog({
    required String title,
    required String message,
    required IconData icon,
    bool isError = false,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _DataTransferDialog(
          icon: icon,
          iconColor: isError ? Colors.redAccent : AppColor.blueMainColor,
          title: title,
          message: message,
          primaryLabel: 'OK',
          onPrimary: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  void _updateBusyDetail(String detail) {
    if (!mounted) return;
    setState(() {
      _busyDetail = detail;
    });
  }

  Future<void> _deleteAllData() async {
    final currentUser = context.read<UserUidProvider>().userUid;
    final timerProvider = context.read<ActivityTimerProvider>();
    if (currentUser == null) {
      await _showTransferResultDialog(
        title: 'User Loading',
        message: 'Your account is still loading. Please try again.',
        icon: Icons.person_search_rounded,
        isError: true,
      );
      return;
    }

    final summary = await _csvTransfer.dataSummaryForUser(
      currentUser: currentUser,
    );
    if (summary.totalRows == 0) {
      await _showTransferResultDialog(
        title: 'No Data To Delete',
        message: 'There is no local Motion data for this account yet.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    final confirmed = await _confirmDeleteAllData();
    if (!confirmed) {
      await _showTransferResultDialog(
        title: 'Cancelled',
        message: 'No data was deleted.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    await _runWithFeedback(
      'Deleted',
      (currentUser) async {
        _updateBusyDetail('Creating automatic backup...');
        final backupMessage = await _createAutomaticBackup(currentUser);
        _updateBusyDetail('Deleting local Motion data...');
        final summary = await _csvTransfer.deleteAllDataForUser(
          currentUser: currentUser,
        );
        await timerProvider.discard();

        if (!mounted) return '${summary.totalRows} row(s).';

        context
            .read<SubcategoryTrackerDatabaseProvider>()
            .refreshAllTrackingData();
        await context.read<AssignerMainProvider>().getAllUserItems();
        _refreshDataSummary();

        return '${summary.totalRows} row(s): '
            '${summary.subcategoryRows} tracking, '
            '${summary.mainCategoryRows} main category, '
            '${summary.experiencePointRows} XP, '
            '${summary.assignerRows} assigned, '
            '${summary.activeTimerRows} timer.\n$backupMessage';
      },
      busyTitle: 'Deleting Data',
      busyDetail: 'Removing your local Motion records...',
    );
  }

  Widget _transferButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    bool isDanger = false,
  }) {
    final iconColor = isDanger ? Colors.redAccent : AppColor.blueMainColor;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: AppTextStyle.subSectionTextStyle(fontsize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyle.manualHintTextStyle(fontsize: 13),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _isBusy ? null : onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserUidProvider>().userUid;

    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                'Create or restore complete Motion backups using your device or Google Drive.',
                style: AppTextStyle.manualHintTextStyle(fontsize: 13),
              ),
              const SizedBox(height: 12),
              if (currentUser == null)
                const _DataSummaryLoadingCard()
              else
                FutureBuilder<MotionDataSummary>(
                  future: _loadDataSummary(currentUser, _summaryRefreshKey),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const _DataSummaryLoadingCard();
                    }
                    return _DataSummaryCard(summary: snapshot.data!);
                  },
                ),
              const SizedBox(height: 12),
              Consumer<AutoDriveBackupProvider>(
                builder: (context, backup, child) {
                  return BackupHealthCard(
                    backup: backup,
                    onChanged:
                        _isBusy ? null : (value) => backup.setEnabled(value),
                    onRunNow: _isBusy || !backup.isEnabled || backup.isRunning
                        ? null
                        : () => backup.runBackupIfEligible(force: true),
                  );
                },
              ),
              const SizedBox(height: 12),
              _transferButton(
                icon: Icons.download,
                title: 'Export Backup',
                subtitle:
                    'Save all three Motion data files to your device or Google Drive.',
                onPressed: _showExportBackupOptions,
              ),
              const SizedBox(height: 12),
              _transferButton(
                icon: Icons.restore_rounded,
                title: 'Restore Motion Backup',
                subtitle:
                    'Restore a complete Motion backup from your device or Google Drive.',
                onPressed: _showRestoreBackupOptions,
              ),
              const SizedBox(height: 12),
              Text(
                'Danger Zone',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 14,
                  fontweight: FontWeight.w900,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 6),
              _transferButton(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Local Data',
                subtitle:
                    'Remove tracking history, XP, assignments, and streak settings for this account.',
                onPressed: _deleteAllData,
                isDanger: true,
              ),
            ],
          ),
          if (_isBusy)
            _BusyTransferOverlay(
              title: _busyTitle,
              detail: _busyDetail,
            ),
        ],
      ),
    );
  }
}
