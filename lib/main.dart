import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:motion/firebase_options.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:motion/motion_routes/home_route.dart';
import 'motion_providers/zen_quotes_provider.dart';
import 'motion_routes/motion_route.dart';
import 'motion_themes/widget_bg_color.dart';
import 'motion_themes/motion_text_styling.dart';
import 'motion_routes/stats_route.dart';
import 'motion_user/auth_page.dart';

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
        theme: ThemeData(
          textTheme: TextTheme(
            bodySmall: contentStyle()
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            titleTextStyle: appTitleStyle,
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          brightness: Brightness.light,
        ),

        // dark mode theme data
        darkTheme: ThemeData(
            dialogTheme: DialogTheme(backgroundColor: darkThemeWidgetBgColor),
            popupMenuTheme: PopupMenuThemeData(color: darkThemeWidgetBgColor),
            appBarTheme: AppBarTheme(
                centerTitle: true,
                titleTextStyle: appTitleStyle,
                backgroundColor: darkThemeWidgetBgColor),
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            brightness: Brightness.dark),

        // theme mode setter
        themeMode: themeValue.currentThemeMode == ThemeModeSettings.lightMode
            ? ThemeMode.light
            : ThemeMode.dark,

        home: const AuthPage(),
      );
    });
  }
}

// Scaffold and Bottom App Bar routes
class MainMotionHome extends StatefulWidget {
  const MainMotionHome({super.key});

  @override
  State<MainMotionHome> createState() => _MotionHome();
}

class _MotionHome extends State<MainMotionHome> {
  // current page index
  int currentIndex = 0;

  // main app routes in the app
  List motionAppRoutes = const [
    MotionHomeRoute(),
    MotionStatesRoute(),
  ];

  // get appropriate colors for bottom app bar element
  Color getIconAndTextColor(BuildContext context, int navIndex) {
    final themeValue = Provider.of<AppThemeModeProvider>(context);
    final themeMode = themeValue.currentThemeMode;

    if (themeMode == ThemeModeSettings.lightMode) {
      return navIndex == currentIndex ? const Color(0xFF00B0F0) : Colors.black;
    } else {
      return navIndex == currentIndex ? const Color(0xFF00B0F0) : Colors.white;
    }
  }

  // bottom appbar builder
  Widget _buildNavButton({
    required int navIndex,
    required Widget navIconImage,
    required Text navName,
  }) {
    final iconAndTextColor = getIconAndTextColor(context, navIndex);

    // icon and name for the bottom nav bar elements
    return ElevatedButton(
        style: ButtonStyle(
            elevation: MaterialStateProperty.all(0),
            backgroundColor: MaterialStateProperty.all(Colors.transparent)),
        onPressed: () {
          setState(() {
            currentIndex = navIndex;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                iconAndTextColor,
                BlendMode.srcIn,
              ),
              child: navIconImage,
            ),
            Text(
              navName.data!,
              style: TextStyle(color: iconAndTextColor),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProvider>(
        builder: (context, themeValue, child) {
      return Scaffold(
        // the app body of the current index
        body: motionAppRoutes[currentIndex],

        // centered Motion logo floating action button
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: SizedBox(
            width: 70,
            height: 70,
            child: FloatingActionButton.large(
              backgroundColor:
                  themeValue.currentThemeMode == ThemeModeSettings.lightMode
                      ? Colors.black
                      : Colors.white,
              elevation: 0,
              shape: const CircleBorder(),
              child: themeValue.currentThemeMode == ThemeModeSettings.lightMode
                  ? SvgPicture.asset(
                      "assets/images/motion_icons/motion_logo_white.svg",
                      height: 30,
                      width: 30,
                    )
                  : SvgPicture.asset(
                      "assets/images/motion_icons/motion_logo.svg",
                      height: 30,
                      width: 30,
                    ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MotionTrackRoute()));
              },
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // bottom navigation bar
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          height: 68,
          notchMargin: 0,
          child: Container(
            color: themeValue.currentThemeMode == ThemeModeSettings.darkMode
                ? darkThemeWidgetBgColor
                : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // home
                _buildNavButton(
                    navIndex: 0,
                    navIconImage: Image.asset(
                      "assets/images/motion_icons/home_route.png",
                      fit: BoxFit.contain,
                      height: 24,
                      width: 24,
                    ),
                    navName: const Text(
                      "Home",
                    )),

                // stats
                _buildNavButton(
                    navIndex: 1,
                    navIconImage: const Icon(
                      Icons.bubble_chart_outlined,
                    ),
                    navName: const Text(
                      "Stats",
                    )),
              ],
            ),
          ),
        ),
      );
    });
  }
}
