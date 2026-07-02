import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_cloud/google_drive_backup_service.dart';
import 'package:motion/motion_core/mc_csv/csv_data_transfer.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class DataTransferPage extends StatefulWidget {
  const DataTransferPage({super.key});

  @override
  State<DataTransferPage> createState() => _DataTransferPageState();
}

class _DataTransferPageState extends State<DataTransferPage> {
  final MotionCsvDataTransfer _csvTransfer = MotionCsvDataTransfer();
  final GoogleDriveBackupService _driveBackupService =
      GoogleDriveBackupService();
  bool _isBusy = false;
  String _busyTitle = 'Working';
  String _busyDetail = 'Please wait...';
  double? _busyProgress;
  int _summaryRefreshKey = 0;

  Future<void> _runWithFeedback(
    String successMessage,
    Future<String> Function(String currentUser) action, {
    String busyTitle = 'Working',
    String busyDetail = 'Please wait...',
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
      title = 'Transfer Failed';
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
    double? progress,
  }) {
    if (!mounted) return;
    setState(() {
      _isBusy = true;
      _busyTitle = title;
      _busyDetail = detail;
      _busyProgress = progress;
    });
  }

  void _stopBusy() {
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _busyProgress = null;
    });
  }

  void _updateImportProgress(MotionCsvImportProgress progress) {
    if (!mounted) return;
    setState(() {
      _busyTitle = 'Importing ${progress.fileLabel}';
      _busyDetail =
          '${progress.importedRows} imported - ${progress.processedRows} of ${progress.totalRows} rows checked';
      _busyProgress = progress.value.clamp(0.0, 1.0).toDouble();
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

  String _formatDateRange(String? firstDate, String? lastDate) {
    if (firstDate == null || firstDate.isEmpty) return 'No tracked dates yet';
    if (lastDate == null || lastDate.isEmpty || firstDate == lastDate) {
      return firstDate;
    }
    return '$firstDate - $lastDate';
  }

  String _formatPreviewMessage({
    required MotionCsvPreview preview,
    required String confirmationMessage,
  }) {
    final dateRange = _formatDateRange(preview.firstDate, preview.lastDate);
    return '$confirmationMessage\n\n'
        'File: ${preview.fileName}\n'
        'Rows found: ${preview.totalRows}\n'
        'Rows ready to import: ${preview.validRows}\n'
        'Rows that will be skipped: ${preview.skippedRows}\n'
        'Date range: $dateRange\n\n'
        'Motion will create an automatic backup before importing this file.';
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
    final selectedOption = await showDialog<_BackupExportOption>(
      context: context,
      builder: (dialogContext) {
        return _ExportBackupOptionsDialog(
          onDevice: () =>
              Navigator.of(dialogContext).pop(_BackupExportOption.device),
          onGoogleDrive: () =>
              Navigator.of(dialogContext).pop(_BackupExportOption.googleDrive),
          onCancel: () =>
              Navigator.of(dialogContext).pop(_BackupExportOption.cancel),
        );
      },
    );

    switch (selectedOption) {
      case _BackupExportOption.device:
        await _exportCsv();
        break;
      case _BackupExportOption.googleDrive:
        await _exportCsvToGoogleDrive();
        break;
      case _BackupExportOption.cancel:
      case null:
        break;
    }
  }

  Future<void> _exportCsvToGoogleDrive() async {
    await _runWithFeedback(
      'Google Drive backup complete:',
      (currentUser) async {
        _updateBusyDetail('Preparing backup files from your database...');
        final backupFiles = await _csvTransfer.backupFiles(
          currentUser: currentUser,
        );

        _updateBusyDetail('Connecting to Google Drive...');
        final motionEmail = FirebaseAuth.instance.currentUser?.email;
        final result = await _driveBackupService.uploadBackupFiles(
          files: backupFiles,
          expectedEmail: motionEmail,
        );

        final accountNote = result.emailMatchesMotionAccount
            ? ''
            : '\nNote: this backup was saved to ${result.email}, which is not the same email currently shown on your Motion account.';
        return '${result.fileCount} file(s) saved to '
            '${result.folderName} in ${result.email}.$accountNote';
      },
      busyTitle: 'Backing Up To Google Drive',
      busyDetail: 'Preparing your data...',
    );
  }

  Future<bool> _confirmImport({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _DataTransferDialog(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColor.workPieChartColor,
          title: title,
          message: message,
          primaryLabel: 'Continue',
          secondaryLabel: 'Cancel',
          onPrimary: () => Navigator.of(dialogContext).pop(true),
          onSecondary: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );

    return result ?? false;
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

  Future<void> _importCsv({
    required MotionCsvFileType fileType,
    required String expectedFileName,
    required String confirmationMessage,
  }) async {
    final selectedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      allowMultiple: false,
    );
    final filePath = selectedFile?.files.single.path;
    if (filePath == null) {
      await _showTransferResultDialog(
        title: 'Cancelled',
        message: 'No file was selected.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    MotionCsvPreview preview;
    try {
      preview = await _csvTransfer.previewCsv(
        fileType: fileType,
        filePath: filePath,
      );
    } catch (error) {
      await _showTransferResultDialog(
        title: 'Invalid CSV',
        message: '$error',
        icon: Icons.error_outline_rounded,
        isError: true,
      );
      return;
    }
    if (preview.validRows == 0) {
      await _showTransferResultDialog(
        title: 'No Importable Rows',
        message:
            '${preview.fileName} does not contain any valid rows for this import action.',
        icon: Icons.error_outline_rounded,
        isError: true,
      );
      return;
    }

    final confirmed = await _confirmImport(
      title: 'Import ${preview.fileName}?',
      message: _formatPreviewMessage(
        preview: preview,
        confirmationMessage: confirmationMessage,
      ),
    );
    if (!confirmed) {
      await _showTransferResultDialog(
        title: 'Cancelled',
        message: 'Import cancelled.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    await _runWithFeedback('Imported', (currentUser) async {
      _updateBusyDetail('Creating automatic backup...');
      final backupMessage = await _createAutomaticBackup(currentUser);
      _updateBusyDetail('Importing ${preview.fileName}...');

      final result = await _csvTransfer.importCsv(
        fileType: fileType,
        filePath: filePath,
        currentUser: currentUser,
        onProgress: _updateImportProgress,
      );

      if (!mounted) {
        return '${result.importedRows} row(s) from $expectedFileName.';
      }

      switch (fileType) {
        case MotionCsvFileType.mainCategory:
          break;
        case MotionCsvFileType.subcategory:
          context
              .read<SubcategoryTrackerDatabaseProvider>()
              .refreshAllTrackingData();
          break;
        case MotionCsvFileType.assigner:
          await context.read<AssignerMainProvider>().getAllUserItems();
          break;
      }
      _refreshDataSummary();

      final rebuiltMessage = result.rebuiltDailyRows > 0
          ? '\nRebuilt ${result.rebuiltDailyRows} daily summaries.'
          : '';
      return '${result.importedRows} row(s) from ${preview.fileName}.\n'
          'Skipped ${result.skippedRows} invalid row(s).'
          '$rebuiltMessage\n$backupMessage';
    },
        busyTitle: 'Importing $expectedFileName',
        busyDetail: 'Preparing the selected file...',
    );
  }

  void _updateBusyDetail(String detail) {
    if (!mounted) return;
    setState(() {
      _busyDetail = detail;
      _busyProgress = null;
    });
  }

  Future<void> _deleteAllData() async {
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

    await _runWithFeedback('Deleted', (currentUser) async {
      _updateBusyDetail('Creating automatic backup...');
      final backupMessage = await _createAutomaticBackup(currentUser);
      _updateBusyDetail('Deleting local Motion data...');
      final summary = await _csvTransfer.deleteAllDataForUser(
        currentUser: currentUser,
      );

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
          '${summary.assignerRows} assigned.\n$backupMessage';
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
                'Export creates a backup of your Motion data. Import uses subcategory.csv and to_assign.csv; main_category.csv is rebuilt from tracking history.',
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
              _transferButton(
                icon: Icons.download,
                title: 'Export Backup',
                subtitle:
                    'Save all three Motion data files to your device or Google Drive.',
                onPressed: _showExportBackupOptions,
              ),
              _transferButton(
                icon: Icons.upload_file,
                title: 'Import Tracking Data',
                subtitle:
                    'Use subcategory.csv to replace tracking history and rebuild XP.',
                onPressed: () => _importCsv(
                  fileType: MotionCsvFileType.subcategory,
                  expectedFileName: 'subcategory.csv',
                  confirmationMessage:
                      'This will replace your current tracking history. Motion will rebuild main category totals and XP from the imported subcategory rows.',
                ),
              ),
              _transferButton(
                icon: Icons.playlist_add_check_rounded,
                title: 'Import Assigned Subcategories',
                subtitle:
                    'Use to_assign.csv to replace assignments and streak settings.',
                onPressed: () => _importCsv(
                  fileType: MotionCsvFileType.assigner,
                  expectedFileName: 'to_assign.csv',
                  confirmationMessage:
                      'This will replace your current assigned subcategory list, active/archive values, and streak settings.',
                ),
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
          if (_isBusy) _BusyTransferOverlay(
            title: _busyTitle,
            detail: _busyDetail,
            progress: _busyProgress,
          ),
        ],
      ),
    );
  }
}

enum _BackupExportOption { device, googleDrive, cancel }

class _ExportBackupOptionsDialog extends StatelessWidget {
  const _ExportBackupOptionsDialog({
    required this.onDevice,
    required this.onGoogleDrive,
    required this.onCancel,
  });

  final VoidCallback onDevice;
  final VoidCallback onGoogleDrive;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final detailColor = isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColor.blueMainColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.backup_rounded,
                      color: AppColor.blueMainColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Export Backup',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 17,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose where Motion should save your database backup files.',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12.5,
                  fontweight: FontWeight.normal,
                  color: detailColor,
                ),
              ),
              const SizedBox(height: 14),
              _BackupOptionTile(
                icon: Icons.phone_android_rounded,
                title: 'Save to Device',
                subtitle: 'Creates CSV files in your Downloads folder.',
                borderColor: borderColor,
                onTap: onDevice,
              ),
              const SizedBox(height: 10),
              _BackupOptionTile(
                icon: Icons.cloud_upload_rounded,
                title: 'Save to Google Drive',
                subtitle: 'Updates the files in your Motion Backups folder.',
                borderColor: borderColor,
                onTap: onGoogleDrive,
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: detailColor,
                  minimumSize: const Size(0, 44),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupOptionTile extends StatelessWidget {
  const _BackupOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final detailColor = isDarkMode ? Colors.white70 : Colors.blueGrey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.035)
              : Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: AppColor.blueMainColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColor.blueMainColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 14,
                      fontweight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12,
                      fontweight: FontWeight.normal,
                      color: detailColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColor.blueMainColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _BusyTransferOverlay extends StatelessWidget {
  const _BusyTransferOverlay({
    required this.title,
    required this.detail,
    required this.progress,
  });

  final String title;
  final String detail;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final detailColor = isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Container(
      color: Colors.black.withValues(alpha: isDarkMode ? 0.42 : 0.18),
      alignment: Alignment.center,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColor.blueMainColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 15,
                fontweight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12,
                fontweight: FontWeight.normal,
                color: detailColor,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: AppColor.blueMainColor.withValues(alpha: 0.16),
                color: AppColor.blueMainColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataSummaryLoadingCard extends StatelessWidget {
  const _DataSummaryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColor.blueMainColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading data summary...',
              style: AppTextStyle.manualHintTextStyle(fontsize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataSummaryCard extends StatelessWidget {
  const _DataSummaryCard({required this.summary});

  final MotionDataSummary summary;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black12;
    final dateRange = summary.firstTrackedDate == null
        ? 'No tracked dates yet'
        : summary.firstTrackedDate == summary.lastTrackedDate
            ? summary.firstTrackedDate!
            : '${summary.firstTrackedDate} - ${summary.lastTrackedDate}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: AppColor.blueMainColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    color: AppColor.blueMainColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Local Data',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 15,
                          fontweight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateRange,
                        style: AppTextStyle.manualHintTextStyle(fontsize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryPill(
                  label: 'Tracking',
                  value: summary.subcategoryRows,
                  borderColor: borderColor,
                ),
                _SummaryPill(
                  label: 'Daily totals',
                  value: summary.mainCategoryRows,
                  borderColor: borderColor,
                ),
                _SummaryPill(
                  label: 'XP days',
                  value: summary.experiencePointRows,
                  borderColor: borderColor,
                ),
                _SummaryPill(
                  label: 'Assigned',
                  value: summary.assignerRows,
                  borderColor: borderColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.borderColor,
  });

  final String label;
  final int value;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.035)
            : Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 14,
              fontweight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyle.manualHintTextStyle(fontsize: 11),
          ),
        ],
      ),
    );
  }
}

class _DataTransferDialog extends StatelessWidget {
  const _DataTransferDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isDangerAction = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isDangerAction;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 17,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.035)
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: borderColor),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      message,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 12.5,
                        fontweight: FontWeight.normal,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (secondaryLabel != null && onSecondary != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSecondary,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: secondaryTextColor,
                          minimumSize: const Size(0, 44),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(secondaryLabel!),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPrimary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDangerAction
                            ? Colors.redAccent
                            : AppColor.blueMainColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(primaryLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
