import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_csv/csv_data_transfer.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
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
  bool _isBusy = false;

  Future<void> _runWithFeedback(
    String successMessage,
    Future<String> Function(String currentUser) action,
  ) async {
    final currentUser = context.read<UserUidProvider>().userUid;
    if (currentUser == null) {
      snackBarMessage(context, errorMessage: 'User is still loading.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      final detail = await action(currentUser);
      if (!mounted) return;
      snackBarMessage(context, errorMessage: '$successMessage $detail');
    } catch (error) {
      if (!mounted) return;
      snackBarMessage(
        context,
        errorMessage: 'Data transfer failed: $error',
        requiresColor: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportCsv() async {
    await _runWithFeedback('Exported CSV files to', (currentUser) async {
      try {
        return await _csvTransfer.exportAllToDownloads(
          currentUser: currentUser,
        );
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
    });
  }

  Widget _transferButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColor.blueMainColor),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                'Export writes main_category.csv, subcategory.csv, and to_assign.csv for your account. Motion will try Downloads first, then ask you to choose a folder if your device blocks direct access.',
                style: AppTextStyle.manualHintTextStyle(fontsize: 13),
              ),
              const SizedBox(height: 12),
              _transferButton(
                icon: Icons.download,
                title: 'Export CSV files',
                subtitle: 'Save all three Motion data files to your device.',
                onPressed: _exportCsv,
              ),
            ],
          ),
          if (_isBusy)
            const Center(
              child: CircularProgressIndicator(color: AppColor.blueMainColor),
            ),
        ],
      ),
    );
  }
}
