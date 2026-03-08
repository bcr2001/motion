import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:motion/firebase_options.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart' show Subcategories;
import 'package:motion/motion_core/mc_sqlite/sql_assigner_db.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_time_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/seven_days_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_user/mu_ops/auth_page.dart';
import 'package:provider/provider.dart';
import 'motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'motion_core/motion_providers/web_api_pvd/zen_quotes_pvd.dart';
import 'motion_themes/mth_theme/dark_theme.dart';
import 'motion_themes/mth_theme/light_theme.dart';
import 'motion_core/mc_sqlite/sql_tracker_db.dart';



// This creates a global key for managing the state of a navigator widget
// in Flutter.
final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

// This instantiates a database helper class (TrackerDatabaseHelper) for
// managing database operations, likely related to tracking functionality.
final TrackerDatabaseHelper trackDbInstance = TrackerDatabaseHelper();


final TrackerDatabaseHelper databaseHelper = TrackerDatabaseHelper();

// MANUALLY ADDING DATA TO THE SUBCATEGORY DATABASE

Future<String> loadCsvFromAssets(String fileName) async {
  final data = await rootBundle.loadString('assets/$fileName');
  return data;
}

// important functions

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
        selfDevelopment : double.parse(row[4].toString()),
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

Future<void> insertTempCsvData() async {
  try {
    final csvRaw = await rootBundle.loadString('assets/data_csv/to_assign.csv');

    final List<String> lines = const LineSplitter().convert(csvRaw);
    final headers = lines.first.split(',');

    for (int i = 1; i < lines.length; i++) {
      final row = lines[i].split(',');

      final assigner = Assigner(
        currentLoggedInUser: row[headers.indexOf("currentLoggedInUser")],
        subcategoryName: row[headers.indexOf("subcategoryName")],
        mainCategoryName: row[headers.indexOf("mainCategoryName")],
        isActive: int.parse(row[headers.indexOf("isActive")]),
        isArchive: int.parse(row[headers.indexOf("isArchive")]),
        dateCreated: _convertToIsoDate(row[headers.indexOf("dateCreated")]),
      );

      await AssignerDatabaseHelper().assignInsert(assigner);
    }

    logger.i("✅ CSV data successfully inserted!");
  } catch (e) {
    logger.i("⛔ Error importing CSV data: $e");
  }
}

// Convert MM/DD/YYYY to YYYY-MM-DD format
String _convertToIsoDate(String input) {
  try {
    // Try M/d/yyyy first (e.g., 9/1/2023)
    return DateFormat("yyyy-MM-dd").format(DateFormat("M/d/yyyy").parseStrict(input));
  } catch (_) {
    try {
      // Fallback to d/M/yyyy (e.g., 25/4/2025)
      return DateFormat("yyyy-MM-dd").format(DateFormat("d/M/yyyy").parseStrict(input));
    } catch (e) {
      logger.e("Date parsing failed for input: $input — Error: $e");
      return ""; // or throw, or default value
    }
  }
}



double _parseDouble(String? value) {
  if (value == null || value.trim().isEmpty) return 0.0;
  return double.tryParse(value.trim()) ?? 0.0;
}


// // Convert MM/DD/YYYY to YYYY-MM-DD format
// String _convertToIsoDate(String input) {
//   try {
//     // Try M/d/yyyy first (e.g., 9/1/2023)
//     return DateFormat("yyyy-MM-dd").format(DateFormat("M/d/yyyy").parseStrict(input));
//   } catch (_) {
//     try {
//       // Fallback to d/M/yyyy (e.g., 25/4/2025)
//       return DateFormat("yyyy-MM-dd").format(DateFormat("d/M/yyyy").parseStrict(input));
//     } catch (e) {
//       logger.e("Date parsing failed for input: $input — Error: $e");
//       return ""; // or throw, or default value
//     }
//   }
// }


// -----------------------------------------------------------------------------
// Helper: convert “M/d/yyyy” or “d/M/yyyy” → ISO “yyyy-MM-dd”
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Updated insertMainCategoryCsvData WITH date normalization
// -----------------------------------------------------------------------------
Future<void> insertMainCategoryCsvData() async {
  final db = TrackerDatabaseHelper(); // or however you get your helper
  try {
    final csvString = await rootBundle.loadString('assets/data_csv/main_category.csv');
    final lines = const LineSplitter().convert(csvString);
    final headers = lines.first.split(',');

    for (var i = 1; i < lines.length; i++) {
      final values = lines[i].split(',');
      if (values.length != headers.length) {
        logger.i("⚠️ Skipping line $i: column count mismatch");
        continue;
      }

      // Build a map of header→value
      final row = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        row[headers[j].trim()] = values[j].trim();
      }

      // 1) Normalize date
      final rawDate = row['date']!;
      final isoDate = _convertToIsoDate(rawDate);
      if (isoDate.isEmpty) {
        logger.i("⚠️ Skipping line $i: invalid date “$rawDate”");
        continue;
      }

      // 2) Parse numeric fields safely
      double parseDouble(String? v) {
        if (v == null || v.isEmpty) return 0.0;
        return double.tryParse(v) ?? 0.0;
      }

      // 3) Construct and insert
      final mainCategory = MainCategory(
        date: isoDate,                              // “2022-01-01”
        education: parseDouble(row['education']),
        // NOTE: your CSV header is “skill” (singular), not “skills”
        skills: parseDouble(row['skill']),
        entertainment: parseDouble(row['entertainment']),
        selfDevelopment: parseDouble(row['selfDevelopment']),
        sleep: parseDouble(row['sleep']),
        currentLoggedInUser: row['currentLoggedInUser']!,
      );

      await db.insertMainCategory(mainCategory);
      logger.i("✅ Inserted MainCategory($isoDate)");
    }

    logger.i("🎉 All main_category.csv rows processed.");
  } catch (e, st) {
    logger.i("❌ Error inserting main_category.csv: $e\n$st");
  }
}


Future<void> insertSubcategoryCsvData() async {
  try {
    final csvString = await rootBundle.loadString('assets/data_csv/subcategory.csv');
    final lines = const LineSplitter().convert(csvString);
    final headers = lines.first.split(',');

    for (int i = 1; i < lines.length; i++) {
      final values = lines[i].split(',');

      // Build a header→value map
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j].trim()] = values[j].trim();
      }

      // 1) Normalize & validate date
      final rawDate = row['date'] ?? '';
      final isoDate = _convertToIsoDate(rawDate);
      if (isoDate.isEmpty) {
        logger.i('⚠️ Skipping line $i: invalid or missing date (“$rawDate”)');
        continue;
      }

      // 2) Pull other required fields safely
      final subcategoryName    = row['subcategoryName']    ?? '';
      final mainCategoryName   = row['mainCategoryName']   ?? '';
      final timeRecorded       = row['timeRecorded']       ?? '';
      final currentLoggedInUser= row['currentLoggedInUser']?? '';

      // 3) Parse the numeric field
      final timeSpent = _parseDouble(row['timeSpent']);

      // 4) Construct and insert
      final subcategory = Subcategories(
        date:                 isoDate,               // now guaranteed “yyyy-MM-dd”
        mainCategoryName:     mainCategoryName,
        subcategoryName:      subcategoryName,
        timeRecorded:         timeRecorded,
        timeSpent:            timeSpent,
        currentLoggedInUser:  currentLoggedInUser,
      );

      await databaseHelper.insertSubcategory(subcategory);
      logger.i('✅ Inserted Subcategory(${subcategory.subcategoryName}) on $isoDate');
    }

    logger.i('🎉 All subcategory.csv rows processed.');
  } catch (e) {
    logger.e('❌ Error inserting subcategory.csv: $e');
  }
}





void main() async {

   // Ensures that the Flutter framework is fully initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------------
  // Inside the main()
  final dbHelper = AssignerDatabaseHelper();

  // Load CSV data from a file (assuming it's in the assets folder)
  final csvString = await loadCsvFromAssets("data/to_assign.csv");


  // Parse the CSV data
  final List<List<dynamic>> csvData =
      const CsvToListConverter().convert(csvString);

  // Check if there is at least one row in the CSV data (headers + data)
  if (csvData.isNotEmpty) {
    // Skip the first row (headers) and create Assigner instances from the rest of the data
    for (var i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      String currentLoggedInUser = row[0].toString();
      String subcategoryName = row[1].toString();
      String mainCategoryName = row[2].toString();
      int isActive;
      String dateCreated = row[4].toString();

      try {
        isActive = int.parse(row[3].toString());
      } catch (e) {
        // Handle the case where 'isActive' cannot be parsed as an integer.
        // You can set a default value or handle the error as appropriate for your use case.
        isActive =
            0; // Assuming 0 as the default value when there's an issue with 'isActive'.
      }

      final assigner = Assigner(
        currentLoggedInUser: currentLoggedInUser,
        subcategoryName: subcategoryName,
        mainCategoryName: mainCategoryName,
        isActive: isActive,
        dateCreated: dateCreated,
      );

      // Insert the Assigner instance into the database
      await dbHelper.assignInsert(assigner);
    }
  }


  logger.i('Data insertion completed.');


  // inside the main function
// Load CSV data from files
  final mainCategoryCsvString =
      await loadCsvFromAssets('data/main_category.csv');
  final subcategoryCsvString = await loadCsvFromAssets('data/subcategory.csv');

  // Insert data into tables
  // await insertMainCategoryDataFromCsv(mainCategoryCsvString);
  // await insertSubcategoryDataFromCsv(subcategoryCsvString);

  // Perform other tasks if needed

  logger.i('Data insertion from CSV files completed.');

  // ------------------------------------------------------------------------------


  // Initialize the database helper
  final TrackerDatabaseHelper databaseHelper = TrackerDatabaseHelper();

  // databaseHelper.updateCurrentUser();

  // await databaseHelper.populateExperiencePointsFromMainCategory();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ZenQuoteProvider
  final zenQuoteProvider = ZenQuoteProvider();
  await zenQuoteProvider.initializeSharedPreferences();

  // UserUidProvider
  final userUidProvider = UserUidProvider();
  userUidProvider.initializeUidSharedPreferences();

  // AssignerProvider
  final assignerProvider = AssignerMainProvider();
  assignerProvider.getAllUserItems();

  // theme mode provider N1
  final themeModeProviderN1 = AppThemeModeProviderN1();
  themeModeProviderN1.initSharedPreferences();

  // TrackDatabaseProvider

  final trackSubcategoryDatabaseProvider = SubcategoryTrackerDatabaseProvider();

  final trackMainCategoryDatabaseProvider = MainCategoryTrackerProvider();

  // final allMain = await databaseHelper.getMostAndLeastProductiveMonths(getMostProductiveMonth: false, year: "2023");
  // final allMain = await trackDbInstance.getMonthTotalAndAverage("gmIUkJzvrOQp3wltZm6IIxULcjj2", "01/02/2025","28/02/2025", true);

  // // CODE FOR MANUALLY ADDING DATA TO THE SUBCATEGORY DATABASE
  // final now = DateTime.now();
  // const date = "2025-08-15";  // "2025-08-07"
  // final formattedTime = DateFormat('HH:mm:ss').format(now);    // "22:30:00"

  // final subcategory = Subcategories(
  //   date: date,
  //   mainCategoryName: "Entertainment",
  //   subcategoryName: "SM/Anime/MM",
  //   timeRecorded: formattedTime,
  //   timeSpent: 924.0,
  //   currentLoggedInUser: "hhANBj74wiclvfuDLGfuDlFZgJ62",
  // );

  // await databaseHelper.insertSubcategory(subcategory);
  // debugPrint("✅ Correctly formatted subcategory inserted.");

  // await databaseHelper.deleteSubcategoriesByDate("07/08/2025");


  // final allSubs = await databaseHelper.getAllSubcategories();

  // logger.i(allSubs);


  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (context) => ExperiencePointTableProvider()),
      ChangeNotifierProvider(
          create: (context) => FirstAndLastWithSevenDaysDiff()),
      ChangeNotifierProvider.value(value: themeModeProviderN1),
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
    return Consumer<AppThemeModeProviderN1>(
        builder: (context, themeValue, child) {
      return MaterialApp(
          navigatorKey: navigationKey,
          debugShowCheckedModeBanner: false,

          // light mode theme data
          theme: lightThemeData,

          // dark mode theme data
          darkTheme: darkThemeData,

          // theme mode setter
          themeMode:
              themeValue.currentThemeMode == ThemeModeSettingsN1.lightMode
                  ? ThemeMode.light
                  : themeValue.currentThemeMode == ThemeModeSettingsN1.darkMode
                      ? ThemeMode.dark
                      : ThemeMode.system,
          home: const AuthPage());
    });
  }
}
