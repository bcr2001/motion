import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/motion_ai/personalized_daily_forecast.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_rewards/daily_xp_target_status.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyForecastLoader {
  const DailyForecastLoader(this._xpProvider);

  final ExperiencePointTableProvider _xpProvider;

  Future<PersonalizedDailyForecast> load({
    required String currentUser,
    required String currentDate,
    required String currentYear,
  }) async {
    final date =
        MotionDateUtils.parseStoredDate(currentDate) ?? MotionDateUtils.today();
    final firstDate = date.subtract(const Duration(days: 365));
    final initialResults = await Future.wait<Object>([
      _xpProvider.retrieveExperiencePointHistory(
        currentUser: currentUser,
        firstDate: MotionDateUtils.formatDbDate(firstDate),
        lastDate: currentDate,
      ),
      _xpProvider.retrieveYearExperiencePointsEfficiencyScore(
        currentUser: currentUser,
        currentYear: currentYear,
      ),
      _xpProvider.retrieveDailyExperiencePointBreakdown(
        currentUser: currentUser,
        selectedDate: currentDate,
      ),
      _xpProvider.retrieveDailyMainCategoryTimeBreakdown(
        currentUser: currentUser,
        selectedDate: currentDate,
      ),
    ]);
    final history = initialResults[0] as List<ExperiencePoints>;
    final score = initialResults[1] as double;
    final todayBreakdown = initialResults[2] as Map<String, int>;
    final todayTrackedMinutes = initialResults[3] as Map<String, double>;
    final targetStatus = await loadDailyXpTargetStatus(
      xpProvider: _xpProvider,
      currentUser: currentUser,
      currentYear: currentYear,
      currentDate: currentDate,
      currentScore: score,
    );

    return PersonalizedDailyForecastPolicy.forecast(
      date: date,
      history: history,
      todayBreakdown: todayBreakdown,
      todayTrackedMinutes: todayTrackedMinutes,
      earnedXp: targetStatus.earnedXp,
      targetXp: targetStatus.targetXp,
    );
  }
}

class DailyForecastProvider extends ChangeNotifier {
  DailyForecastProvider({
    required ExperiencePointTableProvider xpProvider,
    DailyForecastLoader? loader,
  }) : _loader = loader ?? DailyForecastLoader(xpProvider);

  static const String _seenPreferencePrefix =
      'personalized_daily_forecast_seen_v1';

  final DailyForecastLoader _loader;
  PersonalizedDailyForecast? _forecast;
  String? _forecastUser;
  String? _forecastDate;
  String? _requestKey;
  Object? _error;
  DailyForecastChange? _change;
  bool _isLoading = false;
  bool _isUnread = false;
  bool _disposed = false;
  int _requestSequence = 0;
  Future<void>? _activeRefresh;

  PersonalizedDailyForecast? forecastFor({
    required String currentUser,
    required String currentDate,
  }) {
    if (_forecastUser != currentUser || _forecastDate != currentDate) {
      return null;
    }
    return _forecast;
  }

  bool isLoadingFor({
    required String currentUser,
    required String currentDate,
  }) {
    return _isLoading &&
        (_forecastUser != currentUser ||
            _forecastDate != currentDate ||
            _forecast == null);
  }

  bool isUnreadFor({
    required String currentUser,
    required String currentDate,
  }) {
    return _forecastUser == currentUser &&
        _forecastDate == currentDate &&
        _isUnread;
  }

  Object? errorFor({
    required String currentUser,
    required String currentDate,
  }) {
    if (_forecastUser != currentUser || _forecastDate != currentDate) {
      return null;
    }
    return _error;
  }

  DailyForecastChange? changeFor({
    required String currentUser,
    required String currentDate,
  }) {
    if (_forecastUser != currentUser || _forecastDate != currentDate) {
      return null;
    }
    return _change;
  }

  Future<void> refresh({
    required String currentUser,
    required String currentDate,
    required String currentYear,
    required int experienceRevision,
    bool force = false,
  }) {
    final nextRequestKey =
        '$currentUser|$currentDate|$currentYear|$experienceRevision';
    if (!force && _requestKey == nextRequestKey && _activeRefresh != null) {
      return _activeRefresh!;
    }
    if (!force &&
        _requestKey == nextRequestKey &&
        forecastFor(
              currentUser: currentUser,
              currentDate: currentDate,
            ) !=
            null) {
      return Future<void>.value();
    }

    _requestKey = nextRequestKey;
    final requestSequence = ++_requestSequence;
    final refresh = _performRefresh(
      requestSequence: requestSequence,
      currentUser: currentUser,
      currentDate: currentDate,
      currentYear: currentYear,
    );
    _activeRefresh = refresh;
    return refresh;
  }

  Future<void> _performRefresh({
    required int requestSequence,
    required String currentUser,
    required String currentDate,
    required String currentYear,
  }) async {
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final forecast = await _loader.load(
        currentUser: currentUser,
        currentDate: currentDate,
        currentYear: currentYear,
      );
      final lastSeen = await _readLastSeen(currentUser);
      if (_disposed || requestSequence != _requestSequence) return;

      _forecast = forecast;
      _forecastUser = currentUser;
      _forecastDate = currentDate;
      final currentSnapshot =
          DailyForecastAttentionSnapshot.fromForecast(forecast);
      _change = DailyForecastChange.between(
        lastSeen: lastSeen,
        current: currentSnapshot,
      );
      _isUnread = _change != null;
    } catch (error, stackTrace) {
      if (_disposed || requestSequence != _requestSequence) return;
      _forecast = null;
      _forecastUser = currentUser;
      _forecastDate = currentDate;
      _change = null;
      _isUnread = false;
      _error = error;
      debugPrint('Daily forecast refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (!_disposed && requestSequence == _requestSequence) {
        _isLoading = false;
        _activeRefresh = null;
        notifyListeners();
      }
    }
  }

  Future<void> markSeen({
    required String currentUser,
    required String currentDate,
  }) async {
    final forecast = forecastFor(
      currentUser: currentUser,
      currentDate: currentDate,
    );
    if (forecast == null) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _seenPreferenceKey(currentUser),
      jsonEncode(
        DailyForecastAttentionSnapshot.fromForecast(forecast).toJson(),
      ),
    );
    if (_disposed ||
        _forecastUser != currentUser ||
        _forecastDate != currentDate) {
      return;
    }
    if (_isUnread) {
      _isUnread = false;
      notifyListeners();
    }
  }

  void clearDisplayedChange({
    required String currentUser,
    required String currentDate,
  }) {
    if (_forecastUser == currentUser && _forecastDate == currentDate) {
      _change = null;
    }
  }

  Future<DailyForecastAttentionSnapshot?> _readLastSeen(
    String currentUser,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_seenPreferenceKey(currentUser));
    if (rawValue == null || rawValue.isEmpty) return null;

    try {
      final json = jsonDecode(rawValue);
      if (json is! Map<String, dynamic>) return null;
      return DailyForecastAttentionSnapshot.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  String _seenPreferenceKey(String currentUser) {
    return '${_seenPreferencePrefix}_$currentUser';
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
