
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motion/motion_core/mc_api/api_requests.dart';
import 'package:flutter/material.dart';

import '../../../motion_reusable/general_reuseable.dart';
import '../../../motion_themes/mth_app/app_strings.dart';

// this class handles fetching and
// persisting the Zen Quote of the day
class ZenQuoteProvider extends ChangeNotifier {
  // todays quote
  String _todaysQuote = AppString.zenQuotesDefault;

  // get todays quote
  String get todaysQuote => _todaysQuote;

  // shared preferences instance
  SharedPreferences? _prefs;

  // shared prefence keys
  static const quotekey = "zenQuote";
  static const dateKey = "zenQuoteDate";

  // Stream subscription to listen for connectivity changes
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;


  ZenQuoteProvider() {
    initializeSharedPreferences();
    _initializeConnectivityListener();
  }

  // initializeSharedPreferences function
  Future<void> initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedQuote();
  }

  // Initialize the connectivity listener
  void _initializeConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _checkAndFetchNewQuote();
      }
    });
  }

   // Check the date and fetch a new quote if it's a new day
   Future<void> _checkAndFetchNewQuote() async {
    final savedDate = _prefs?.getString(dateKey);
    if (savedDate == null || !_isToday(DateTime.parse(savedDate))) {
      await fetchTodaysQuote();
    }
  }

  Future<void> fetchTodaysQuote() async {
    // fetches the Future<String> returned
    // when fetchQuote() is executed
    try {
      _todaysQuote = await fetchZenQuote();

      // save preferences
      _prefs?.setString(quotekey, _todaysQuote);
      _prefs?.setString(dateKey, DateTime.now().toIso8601String());

      // notifty listeners of changes
      notifyListeners();
    } catch (e) {
      logger.e("Error: $e");
      _todaysQuote =
          "“Time is what we want most, but what we use worst.” - William Penn";
      notifyListeners();
    }
  }

  // load saved quote
  Future<void> _loadSavedQuote() async {
    final savedQuote = _prefs?.getString(quotekey);
    final savedDate = _prefs?.getString(dateKey);

    if (savedQuote != null &&
        savedDate != null &&
        _isToday(DateTime.parse(savedDate))) {
      _todaysQuote = savedQuote;
      // notify listeners
      notifyListeners();
    } else {
      // if it's the next day, a new quote
      // of the day is fetched
      fetchTodaysQuote();
      notifyListeners();
    }
  }

  // this function checks whether it's the next day
  // or still the current date
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  // Dispose of the connectivity subscription to avoid memory leaks
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
