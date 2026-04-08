import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsProvider extends ChangeNotifier {
  // ── Keys ────────────────────────────────────────────────────
  static const _keyTheme = 'app_theme';
  static const _keyLocale = 'app_locale';
  static const _keyBudgetAlerts = 'budget_alerts';
  static const _keyDailySpent = 'daily_spent';
  static const _keyAlertTime = 'alert_time';

  // ── State ───────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _budgetAlerts = false;
  bool _dailySpent = false;
  String _alertTime = "08:00";

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get budgetAlerts => _budgetAlerts;
  bool get dailySpent => _dailySpent;
  String get alertTime => _alertTime;

  /// Human-readable label used by the Settings dropdown.
  String get themeLabel {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  String get languageLabel => _locale.languageCode == 'ta' ? 'Tamil' : 'English';

  // ── Initialisation (call once from main) ────────────────────
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Try Supabase first (source of truth for logged-in users)
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        final response = await client
            .from('app_preferences')
            .select()
            .eq('user_id', userId)
            .limit(1);

        final List<dynamic> data = response as List<dynamic>;
        if (data.isNotEmpty) {
          final p = data.first;
          final dbTheme = p['theme'] as String? ?? 'System';
          final dbLang = p['language'] as String? ?? 'English';

          _themeMode = _themeModeFrom(dbTheme);
          _locale =
              dbLang == 'Tamil' ? const Locale('ta') : const Locale('en');

          // Keep SharedPreferences in sync
          await prefs.setString(_keyTheme, dbTheme);
          await prefs.setString(_keyLocale, dbLang);

          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Fall through to SharedPreferences
    }

    // Fallback: SharedPreferences (offline / not logged in)
    final savedTheme = prefs.getString(_keyTheme) ?? 'System';
    _themeMode = _themeModeFrom(savedTheme);

    final savedLang = prefs.getString(_keyLocale) ?? 'English';
    _locale = savedLang == 'Tamil' ? const Locale('ta') : const Locale('en');

    _budgetAlerts = prefs.getBool(_keyBudgetAlerts) ?? false;
    _dailySpent = prefs.getBool(_keyDailySpent) ?? false;
    _alertTime = prefs.getString(_keyAlertTime) ?? "08:00";

    notifyListeners();
  }

  // ── Setters (persist + notify) ──────────────────────────────
  Future<void> setTheme(String label) async {
    _themeMode = _themeModeFrom(label);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, label);
  }

  Future<void> setLanguage(String label) async {
    _locale = label == 'Tamil' ? const Locale('ta') : const Locale('en');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, label);
  }

  Future<void> setNotificationSettings(bool budget, bool daily, String time) async {
    _budgetAlerts = budget;
    _dailySpent = daily;
    _alertTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetAlerts, budget);
    await prefs.setBool(_keyDailySpent, daily);
    await prefs.setString(_keyAlertTime, time);
  }

  // ── Private helper ──────────────────────────────────────────
  static ThemeMode _themeModeFrom(String label) {
    switch (label) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
