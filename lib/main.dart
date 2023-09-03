import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:motion/firebase_options.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_db.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_time.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/firestore_provider.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_provider.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_db.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_provider.dart';
import 'package:motion/motion_core/motion_providers/dropDown_pcd/dropDown.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_user/mu_ops/auth_page.dart';

import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'motion_core/motion_providers/date_pvd/current_date.dart';
import 'motion_core/motion_providers/sql_pvd/assigner.dart';
import 'motion_core/motion_providers/web_api_pvd/zen_quotes_provider.dart';
import 'motion_themes/mth_theme/dark_theme.dart';
import 'motion_themes/mth_theme/light_theme.dart';

final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  final activeAssignerProvider = ActiveAssignedProvider();
  activeAssignerProvider.activeSubcategoriesList();

  // TrackDatabaseProvider
  final trackSubcategoryDatabaseProvider = SubcategoryTrackerDatabaseProvider();

  final trackMainCategoryDatabaseProvider = MainCategoryTrackerProvider();

  // Initialize the database helper
  final TrackerDatabaseHelper databaseHelper = TrackerDatabaseHelper();

  final allSubs = databaseHelper.getAllSubcategories();

  print(allSubs);


  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => CurrentTimeProvider()),
      ChangeNotifierProvider.value(value: trackMainCategoryDatabaseProvider),
      ChangeNotifierProvider.value(value: trackSubcategoryDatabaseProvider),
      ChangeNotifierProvider.value(value: assignerProvider),
      ChangeNotifierProvider.value(value: activeAssignerProvider),
      ChangeNotifierProvider.value(value: userUidProvider),
      StreamProvider<User?>.value(
        initialData: null,
        value: FirebaseAuth.instance.authStateChanges(),
      ),
      ChangeNotifierProvider(create: (context) => DropDownTrackProvider()),
      ChangeNotifierProvider(create: (context) => CurrentDataProvider()),
      ChangeNotifierProvider.value(value: appThemeMode),
      ChangeNotifierProvider(create: (context) => zenQuoteProvider),
      ChangeNotifierProvider(create: (context) => FirestoreProvider()),
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
