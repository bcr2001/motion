import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:motion/firebase_options.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:motion/motion_user/auth_page.dart';
import 'package:provider/provider.dart';
import 'motion_providers/zen_quotes_provider.dart';
import 'motion_themes/dark_theme.dart';
import 'motion_themes/light_theme.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // AppThemeModeProvider Instance
  final appThemeMode = AppThemeModeProvider();
  await appThemeMode.initializeSharedPreferences();

  // ZenQuoteProvider
  final zenQuoteProvider = ZenQuoteProvider();
  await zenQuoteProvider.initializeSharedPreferences();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: appThemeMode),
      ChangeNotifierProvider(create: (context) => zenQuoteProvider)
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
        debugShowCheckedModeBanner: false,

        // light mode theme data
        theme: lightThemeData,

        // dark mode theme data
        darkTheme: darkThemeData,

        
        // theme mode setter
        themeMode: themeValue.currentThemeMode == ThemeModeSettings.lightMode
            ? ThemeMode.light
            : ThemeMode.dark,

        home: const AuthPage(),
      );
    });
  }
}