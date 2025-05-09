import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:motion/firebase_options.dart';
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



void main() async {
  WidgetsFlutterBinding.ensureInitialized();


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

  await databaseHelper.backfillXpForExistingUser();
  // final allMain = await databaseHelper.getMostAndLeastProductiveMonths(getMostProductiveMonth: false, year: "2023");
  // final allMain = await trackDbInstance.getMonthTotalAndAverage("gmIUkJzvrOQp3wltZm6IIxULcjj2", "01/02/2025","28/02/2025", true);


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
