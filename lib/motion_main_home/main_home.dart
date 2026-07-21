import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_core/motion_providers/timer_pvd/activity_timer_pvd.dart';
import 'package:motion/motion_reusable/motion_ui/activity_timer_widgets.dart';
import 'package:motion/motion_routes/mr_home/homa_main/home_route.dart';
import 'package:motion/motion_routes/mr_track/track_main/track_route.dart';
import 'package:motion/motion_routes/mr_stats/stats_route.dart';
import 'package:motion/motion_screens/ms_routes/manual_tracking.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../motion_themes/mth_app/app_strings.dart';
import '../motion_themes/mth_styling/motion_text_styling.dart';

// Scaffold and Bottom App Bar routes
class MainMotionHome extends StatefulWidget {
  const MainMotionHome({super.key});

  @override
  State<MainMotionHome> createState() => _MotionHome();
}

class _MotionHome extends State<MainMotionHome> {
  // current page index
  int currentIndex = 0;
  ActivityTimerProvider? _timerProvider;
  bool _reminderDialogVisible = false;

  // main app routes in the app
  List motionAppRoutes = const [
    MotionHomeRoute(),
    MotionStatesRoute(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<ActivityTimerProvider>();
    if (identical(_timerProvider, nextProvider)) return;
    _timerProvider?.removeListener(_handleTimerChanged);
    _timerProvider = nextProvider;
    nextProvider.addListener(_handleTimerChanged);
  }

  @override
  void dispose() {
    _timerProvider?.removeListener(_handleTimerChanged);
    super.dispose();
  }

  void _handleTimerChanged() {
    final timer = _timerProvider;
    if (timer == null ||
        !timer.isReminderDue ||
        _reminderDialogVisible ||
        !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _reminderDialogVisible ||
          !(ModalRoute.of(context)?.isCurrent ?? false)) {
        return;
      }
      _showLongRunningTimerPrompt(timer);
    });
  }

  Future<void> _showLongRunningTimerPrompt(
    ActivityTimerProvider timer,
  ) async {
    final session = timer.session;
    if (session == null) return;
    _reminderDialogVisible = true;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Timer Still Running?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.subcategoryName} has been running for '
              '${formatActivityTimerDuration(timer.elapsedSeconds)}.',
            ),
            const SizedBox(height: 8),
            const Text('Continue, pause it, or review the recorded time.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'pause'),
            child: const Text('Pause'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'continue'),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'review'),
            child: const Text('Review Timer'),
          ),
        ],
      ),
    );
    _reminderDialogVisible = false;
    if (!mounted) return;

    if (action == 'pause') {
      await timer.pause();
    } else if (action == 'continue') {
      await timer.acknowledgeReminder();
    } else if (action == 'review') {
      _openActiveTimer();
    }
  }

  void _openActiveTimer() {
    final session = context.read<ActivityTimerProvider>().session;
    if (session == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualTimeRecordingRoute(
          subcategoryName: session.subcategoryName,
          mainCategoryName: session.mainCategoryName,
        ),
      ),
    );
  }

  // Helper function to build Google Nav Bar buttons
  GButton gButtonBuilder(BuildContext context,
      {required IconData gIcon, required String gText}) {
    return GButton(
        icon: gIcon,
        text: gText,
        textStyle: AppTextStyle.subSectionTextStyle(fontsize: 12),
        iconSize: 20,
        iconColor: Theme.of(context).iconTheme.color);
  }

  // google nav bar button
  // Helper function to build Google Nav Bar buttons
  List<GButton> _navButtons(BuildContext context) {
    return <GButton>[
      // home button
      gButtonBuilder(context,
          gIcon: Icons.home_filled, gText: AppString.homeNavigation),

      // stats button
      gButtonBuilder(context,
          gIcon: Icons.bubble_chart_outlined, gText: AppString.statsNavigation),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProviderN1>(
        builder: (context, themeValue, child) {
      final isLightMode = Theme.of(context).brightness == Brightness.light;

      return Scaffold(
        // the app body of the current index
        body: Stack(
          children: [
            motionAppRoutes[currentIndex],
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                    child: GNav(
                  backgroundColor: isLightMode
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5),
                  haptic: true,
                  curve: Curves.linear,
                  padding: const EdgeInsets.all(8),
                  duration: const Duration(milliseconds: 500),
                  gap: 10.0,
                  tabMargin: const EdgeInsets.all(5),
                  selectedIndex: currentIndex,
                  tabs: _navButtons(context),
                  onTabChange: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                ))),
            Positioned(
              left: 12,
              right: 12,
              bottom: 92,
              child: ActivityTimerCompactBar(onTap: _openActiveTimer),
            ),
          ],
        ),
        // centered Motion logo floating action button
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: SizedBox(
            width: 60,
            height: 60,
            child: FloatingActionButton.large(
              backgroundColor:
                  themeValue.currentThemeMode == ThemeModeSettingsN1.lightMode
                      ? Colors.black
                      : Colors.white,
              elevation: 0,
              shape: const CircleBorder(),
              child:
                  // different svg images depending on the theme mode
                  // (dark/light)
                  themeValue.currentThemeMode == ThemeModeSettingsN1.lightMode
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
                // navigates to the Track route where users can create and
                // assign subcategories to their respective main categories
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MotionTrackRoute()));
              },
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    });
  }
}
