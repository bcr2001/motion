import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_api/api_requests.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Handles fetching and persisting the Zen Quote of the day.
class ZenQuoteProvider extends ChangeNotifier with WidgetsBindingObserver {
  ZenQuoteProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  String _todaysQuote = AppString.zenQuotesDefault;
  SharedPreferences? _prefs;
  Timer? _retryTimer;
  bool _isFetchingQuote = false;

  String get todaysQuote => _todaysQuote;

  static const quoteKey = "zenQuote";
  static const dateKey = "zenQuoteDate";

  Future<void> initializeSharedPreferences() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadSavedQuote();
  }

  Future<void> _checkAndFetchNewQuote() async {
    final savedQuote = _prefs?.getString(quoteKey);
    final savedDate = MotionDateUtils.parseStoredDate(
      _prefs?.getString(dateKey),
    );

    if (_hasFreshRemoteQuote(savedQuote: savedQuote, savedDate: savedDate)) {
      _retryTimer?.cancel();
      return;
    }

    final didFetchQuote = await fetchTodaysQuote();
    if (!didFetchQuote) _scheduleRetry();
  }

  Future<bool> fetchTodaysQuote() async {
    if (_isFetchingQuote) return false;
    _isFetchingQuote = true;

    try {
      final fetchedQuote = await fetchZenQuote();
      if (!_isRemoteQuote(fetchedQuote)) {
        if (_todaysQuote.trim().isEmpty) {
          _todaysQuote = AppString.zenQuotesDefault;
          notifyListeners();
        }
        return false;
      }

      _retryTimer?.cancel();
      _todaysQuote = fetchedQuote!;
      await _prefs?.setString(quoteKey, _todaysQuote);
      await _prefs?.setString(dateKey, MotionDateUtils.todayIso());
      notifyListeners();
      return true;
    } catch (error) {
      logger.e("Error fetching today's quote: $error");
      return false;
    } finally {
      _isFetchingQuote = false;
    }
  }

  Future<void> _loadSavedQuote() async {
    final savedQuote = _prefs?.getString(quoteKey);
    final savedDate = MotionDateUtils.parseStoredDate(
      _prefs?.getString(dateKey),
    );

    if (savedQuote != null && savedQuote.trim().isNotEmpty) {
      _todaysQuote = savedQuote;
      notifyListeners();
    }

    if (!_hasFreshRemoteQuote(savedQuote: savedQuote, savedDate: savedDate)) {
      unawaited(_checkAndFetchNewQuote());
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 2), () {
      unawaited(_checkAndFetchNewQuote());
    });
  }

  bool _hasFreshRemoteQuote({
    required String? savedQuote,
    required DateTime? savedDate,
  }) {
    return savedDate != null &&
        MotionDateUtils.isSameDate(savedDate, MotionDateUtils.today()) &&
        _isRemoteQuote(savedQuote);
  }

  bool _isRemoteQuote(String? quote) {
    final trimmed = quote?.trim();
    return trimmed != null &&
        trimmed.isNotEmpty &&
        trimmed != AppString.defaultAppQuote &&
        trimmed != AppString.zenQuotesDefault;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkAndFetchNewQuote());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    super.dispose();
  }
}
