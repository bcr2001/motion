import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../motion_reusable/general_reuseable.dart';

class ImportDataRoute extends StatelessWidget {
  const ImportDataRoute({super.key});

  Widget _importDataSections(
      {required String sectionTitle,
      required String sectionDescription,
      required String sectionButtonName,
      required VoidCallback onTap,
      bool isLeanMore = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // section title
          isLeanMore
              ? Row(
                  children: [
                    // info icon
                    const Padding(
                      padding: EdgeInsets.only(right: 5.0, top: 2),
                      child: Icon(
                        Icons.info_outlined,
                        size: 25,
                      ),
                    ),

                    // title
                    Text(
                      sectionTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : Text(
                  sectionTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),

          // section description
          Text(
            sectionDescription,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),

          // section button
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                sectionButtonName,
                style: const TextStyle(
                    color: AppColor.blueMainColor, fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.importDataTitle),
      ),
      body: Column(
        children: [
          // import assigner db
          // Import assigner db
          _importDataSections(
            sectionTitle: AppString.importAssignerTitle,
            sectionDescription: AppString.importAssignerDescription,
            sectionButtonName: AppString.importAssignerButtonName,
            onTap: () async {
              logger.i("I was pressed");
              // Get the path to the assigner database
              final directory = await getApplicationDocumentsDirectory();
              final pathToAssignerDatabase = '${directory.path}/assigner.db';

              // Create an instance of ImportFileToMotion and call importDatabase
              await ImportFileToMotion(getDatabasePath: () async {
                return pathToAssignerDatabase;
              }).importDatabase();
            },
          ),

          // import tracker db
          _importDataSections(
              sectionTitle: AppString.importTrackerTitle,
              sectionDescription: AppString.importTrackerDescription,
              sectionButtonName: AppString.importTrackerButtonName,
              onTap: () {}),

          // learn more
          _importDataSections(
              isLeanMore: true,
              sectionTitle: AppString.learnMoreTitle,
              sectionDescription: AppString.learnMoreDescription,
              sectionButtonName: AppString.learnMoreButtonName,
              onTap: () {})
        ],
      ),
    );
  }
}

class ImportFileToMotion {
  final Future<String> Function() getDatabasePath;

  ImportFileToMotion({required this.getDatabasePath});

  Future<void> importDatabase() async {
    // Open the file picker to select a database file
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any // Specify the file type (e.g., SQLite database)
        );

    if (result != null && result.files.isNotEmpty) {
      final PlatformFile file = result.files.first;
      final String? newDatabasePath = file.path;
      if (newDatabasePath != null && newDatabasePath.endsWith('.db')) {
        try {
          // Get the path to the old database file using the callback function
          final String oldDatabasePath = await getDatabasePath();

          // Close the old database (if it's open)
          await _closeDatabase(oldDatabasePath);

          // Copy the new database file to replace the old one
          await File(newDatabasePath!).copy(oldDatabasePath);

          // Reopen the database
          final Database newDatabase = await openDatabase(oldDatabasePath);

          // Now, you can use the newDatabase for your operations
          logger.i("database succesfully selected");
        } catch (e) {
          print('Error importing database: $e');
        }
      } else {
        // Show an error message to the user
        logger.e('Invalid file selected. Please choose a .db file.');
      }
    }
  }

  Future<void> _closeDatabase(String databasePath) async {
    final File oldDatabaseFile = File(databasePath);
    if (oldDatabaseFile.existsSync()) {
      await oldDatabaseFile.delete();
    }
  }
}
