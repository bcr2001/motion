import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion/firebase_options.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_time_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pcd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
import 'package:motion/motion_user/mu_ops/auth_page.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'motion_core/mc_sql_table/assign_table.dart';
import 'motion_core/mc_sql_table/main_table.dart';
import 'motion_core/mc_sql_table/sub_table.dart';
import 'motion_core/mc_sqlite/sql_assigner_db.dart';
import 'motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'motion_core/motion_providers/web_api_pvd/zen_quotes_pvd.dart';
import 'motion_reusable/general_reuseable.dart';
import 'motion_themes/mth_theme/dark_theme.dart';
import 'motion_themes/mth_theme/light_theme.dart';
import 'package:csv/csv.dart';

import 'package:flutter/services.dart' show rootBundle;

Future<String> loadCsvFromAssets(String fileName) async {
  try {
    final data = await rootBundle.loadString('assets/$fileName');
    return data;
  } catch (e) {
    logger.e('Error loading CSV file from assets: $e');
    return '';
  }
}


Future<void> insertMainCategoryDataFromCsv(String csvString) async {
  try {
    final dbHelper = TrackerDatabaseHelper();
    final List<List<dynamic>> csvData =
        const CsvToListConverter().convert(csvString);

    // Start processing from the second row to skip the header row.
    for (var i = 1; i < csvData.length; i++) {
      final row = csvData[i];

      final mainCategory = MainCategory(
        date: row[0].toString(),
        education: double.parse(row[1].toString()),
        skills: double.parse(row[2].toString()),
        entertainment: double.parse(row[3].toString()),
        personalGrowth: double.parse(row[4].toString()),
        sleep: double.parse(row[5].toString()),
        currentLoggedInUser: row[6].toString(),
      );

      await dbHelper.insertMainCategory(mainCategory);
    }

    logger.i('Main category data insertion completed.');
  } catch (e) {
    logger.e('Error inserting main category data: $e');
  }
}

Future<void> insertSubcategoryDataFromCsv(String csvString) async {
  try {
    final dbHelper = TrackerDatabaseHelper();
    final List<List<dynamic>> csvData =
        const CsvToListConverter().convert(csvString);

    // Start processing from the second row to skip the header row.
    for (var i = 1; i < csvData.length; i++) {
      final row = csvData[i];

      final subcategory = Subcategories(
        date: row[0].toString(),
        mainCategoryName: row[1].toString(),
        subcategoryName: row[2].toString(),
        timeRecorded: row[3].toString(),
        timeSpent: double.parse(row[4].toString()),
        currentLoggedInUser: row[5].toString(),
      );

      await dbHelper.insertSubcategory(subcategory);
    }

    logger.i('Subcategory data insertion completed.');
  } catch (e) {
    logger.e('Error inserting subcategory data: $e');
  }
}


final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load CSV data from files
  // final mainCategoryCsvString =
  //     await loadCsvFromAssets('data/main_category.csv');
  // final subcategoryCsvString = await loadCsvFromAssets('data/subcategory.csv');

  // // Insert data into tables
  // await insertMainCategoryDataFromCsv(mainCategoryCsvString);
  // await insertSubcategoryDataFromCsv(subcategoryCsvString);

  // // Perform other tasks if needed

  // logger.i('Data insertion from CSV files completed.');


  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // AppThemeModeProvider Instance
  final appThemeMode = AppThemeModeProvider();
  await appThemeMode.initializeSharedPreferences();

  // ZenQuoteProvider
  final zenQuoteProvider = ZenQuoteProvider();
  await zenQuoteProvider.initializeSharedPreferences();

  // UserUidProvider
  final userUidProvider = UserUidProvider();
  userUidProvider.initializeUidSharedPreferences();

  // AssignerProvider
  final assignerProvider = AssignerMainProvider();
  assignerProvider.getAllUserItems();

  // TrackDatabaseProvider
  final trackSubcategoryDatabaseProvider = SubcategoryTrackerDatabaseProvider();

  final trackMainCategoryDatabaseProvider = MainCategoryTrackerProvider();

  // Initialize the database helper
  // final TrackerDatabaseHelper databaseHelper = TrackerDatabaseHelper();

  // final allMain = await databaseHelper.getAllSubcategories();

  // logger.i(allMain);

  // await databaseHelper.deleteDb();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => FirstAndLastDay()),
      ChangeNotifierProvider(create: (context) => CurrentYearProvider()),
      ChangeNotifierProvider(create: (context) => CurrentTimeProvider()),
      ChangeNotifierProvider.value(value: trackMainCategoryDatabaseProvider),
      ChangeNotifierProvider.value(value: trackSubcategoryDatabaseProvider),
      ChangeNotifierProvider.value(value: assignerProvider),
      ChangeNotifierProvider.value(value: userUidProvider),
      StreamProvider<User?>.value(
        initialData: null,
        value: FirebaseAuth.instance.authStateChanges(),
      ),
      ChangeNotifierProvider(create: (context) => DropDownTrackProvider()),
      ChangeNotifierProvider(create: (context) => CurrentDateProvider()),
      ChangeNotifierProvider.value(value: appThemeMode),
      ChangeNotifierProvider(create: (context) => zenQuoteProvider),
      ChangeNotifierProvider(create: (context) => CurrentMonthProvider())
    ],
    child: const MainMotionApp(),
  ));
}

// Material App and theme configuration
class MainMotionApp extends StatelessWidget {
  const MainMotionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProvider>(
        builder: (context, themeValue, child) {
      return MaterialApp(
          navigatorKey: navigationKey,
          debugShowCheckedModeBanner: false,

          // light mode theme data
          theme: lightThemeData,

          // dark mode theme data
          darkTheme: darkThemeData,

          // theme mode setter
          themeMode: themeValue.currentThemeMode == ThemeModeSettings.lightMode
              ? ThemeMode.light
              : ThemeMode.dark,
          home: const AuthPage());
    });
  }
}
