part of 'data_transfer_page.dart';

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

class _AutoDriveBackupCard extends StatelessWidget {
  const _AutoDriveBackupCard({
    required this.backup,
    required this.onChanged,
    required this.onRunNow,
  });

  final AutoDriveBackupProvider backup;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onRunNow;

  Color _statusColor() {
    switch (backup.status) {
      case AutoDriveBackupStatus.success:
        return AppColor.accountedColor;
      case AutoDriveBackupStatus.pendingOffline:
        return AppColor.workPieChartColor;
      case AutoDriveBackupStatus.blocked:
        return Colors.redAccent;
      case AutoDriveBackupStatus.running:
        return AppColor.blueMainColor;
      case AutoDriveBackupStatus.noData:
      case AutoDriveBackupStatus.idle:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon() {
    switch (backup.status) {
      case AutoDriveBackupStatus.success:
        return Icons.check_circle_rounded;
      case AutoDriveBackupStatus.pendingOffline:
        return Icons.cloud_off_rounded;
      case AutoDriveBackupStatus.blocked:
        return Icons.error_rounded;
      case AutoDriveBackupStatus.running:
        return Icons.sync_rounded;
      case AutoDriveBackupStatus.noData:
        return Icons.info_rounded;
      case AutoDriveBackupStatus.idle:
        return Icons.schedule_rounded;
    }
  }

  String _formatTimestamp(String? value) {
    if (value == null || value.isEmpty) return 'Not backed up yet';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')} at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black12;
    final detailColor = isDarkMode ? Colors.white70 : Colors.blueGrey;
    final statusColor = _statusColor();

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
                    Icons.cloud_sync_rounded,
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
                        'Automatic Google Drive Backup',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 15,
                          fontweight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Runs once per day after 8 PM, or the next time Motion is opened.',
                        style: AppTextStyle.manualHintTextStyle(fontsize: 12),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: backup.isEnabled,
                  onChanged: onChanged,
                  activeColor: AppColor.blueMainColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_statusIcon(), size: 20, color: statusColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          backup.message,
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 12.5,
                            fontweight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Last successful backup: '
                          '${_formatTimestamp(backup.lastSuccessAt)}',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 11.5,
                            fontweight: FontWeight.normal,
                            color: detailColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (backup.isEnabled) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onRunNow,
                  icon: backup.isRunning
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded, size: 17),
                  label: Text(backup.isRunning ? 'Backing Up' : 'Back Up Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.blueMainColor,
                    side: BorderSide(
                      color: AppColor.blueMainColor.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
