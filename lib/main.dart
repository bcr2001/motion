import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:motion/firebase_options.dart';
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
import 'motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'motion_core/motion_providers/web_api_pvd/zen_quotes_pvd.dart';
import 'motion_themes/mth_theme/dark_theme.dart';
import 'motion_themes/mth_theme/light_theme.dart';

final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database helper
  // final TrackerDatabaseHelper databaseHelper = TrackerDatabaseHelper();
  // final dbHelper = AssignerDatabaseHelper();

  // databaseHelper.updateCurrentUser();

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

  // final allMain = await dbHelper.getAllItems();
  // final allMain = await databaseHelper.getAllSubcategories();

  // logger.i(allMain);

  // await dbHelper.deleteDB();

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
