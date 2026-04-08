import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'notification_storage.dart';

/// A service that provides AI-powered budget monitoring features:
///
/// 1. **Auto-correct category names** using Levenshtein string similarity
///    against the user's historical transaction categories.
/// 2. **Budget overrun detection** — compares this month's expenses against the
///    saved budget and fires a local push notification when exceeded.
class BudgetMonitorService {
  BudgetMonitorService._(); // prevent instantiation

  // ── Notification plumbing ─────────────────────────────────────────────
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;

  static Future<void> _ensureNotificationsInitialized() async {
    if (_notificationsInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(settings: initSettings);
    _notificationsInitialized = true;
  }

  // ════════════════════════════════════════════════════════════════════════
  //  1. BUDGET OVERRUN CHECK
  // ════════════════════════════════════════════════════════════════════════

  /// Call this after every expense transaction is saved.
  ///
  /// It fetches the user's budget + this month's expenses, and if expenses
  /// exceed the budget **and** the user has `budget_alerts` enabled, it fires
  /// a high-importance local notification.
  static Future<void> checkBudgetOverrun() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // ── 1a. Check if user has budget_alerts enabled ──────────────────
      final settingsResponse = await client
          .from('user_settings')
          .select('budget_alerts')
          .eq('user_id', userId)
          .limit(1);

      final List<dynamic> settingsData = settingsResponse as List<dynamic>;
      if (settingsData.isNotEmpty) {
        final bool alertsEnabled =
            settingsData.first['budget_alerts'] ?? false;
        if (!alertsEnabled) return; // user doesn't want alerts
      }
      // If no settings row exists, we still proceed (default = alert)

      // ── 1b. Fetch the latest budget ──────────────────────────────────
      final budgetResponse = await client
          .from('budgets')
          .select('total_budget')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      final List<dynamic> budgetData = budgetResponse as List<dynamic>;
      if (budgetData.isEmpty) return; // no budget set

      final double totalBudget =
          (budgetData.first['total_budget'] as num?)?.toDouble() ?? 0.0;
      if (totalBudget <= 0) return;

      // ── 1c. Sum this calendar month's expenses ───────────────────────
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      // End of month: first day of next month
      final monthEnd =
          DateTime(now.year, now.month + 1, 1).toIso8601String();

      final txResponse = await client
          .from('transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('type', 'Expense')
          .gte('created_at', monthStart)
          .lt('created_at', monthEnd);

      final List<dynamic> txData = txResponse as List<dynamic>;
      double totalExpenses = 0.0;
      for (var tx in txData) {
        totalExpenses += (tx['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // ── 1d. Compare and notify ───────────────────────────────────────
      if (totalExpenses > totalBudget) {
        await _fireOverrunNotification(totalBudget, totalExpenses);
      }
    } catch (e) {
      debugPrint('BudgetMonitorService.checkBudgetOverrun error: $e');
    }
  }

  static Future<void> _fireOverrunNotification(
    double budget,
    double expenses,
  ) async {
    await _ensureNotificationsInitialized();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'budget_alerts', // channel ID
      'Budget Alerts', // channel name
      channelDescription: 'Alerts when spending exceeds your monthly budget',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final alertBody = 'You have exceeded your monthly budget of ₹${budget.toStringAsFixed(0)}! '
        'Current spending: ₹${expenses.toStringAsFixed(0)}';

    await _notificationsPlugin.show(
      id: 0, // fixed — overwrites previous overrun alert
      title: '⚠️ FinTrack AI Alert',
      body: alertBody,
      notificationDetails: details,
    );

    // Save to local Notification History
    await NotificationStorage.saveNotification(
      '⚠️ FinTrack AI Alert',
      alertBody,
      type: 'budget_alert',
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  2. SMART CATEGORY AUTO-CORRECTION
  // ════════════════════════════════════════════════════════════════════════

  /// Given the user's budget category list, auto-corrects each category name
  /// by comparing it against unique categories found in their past
  /// transactions. Returns the corrected list.
  ///
  /// The correction uses Levenshtein-based similarity with a 0.6 threshold.
  static Future<List<Map<String, dynamic>>> autoCorrectCategories(
    List<Map<String, dynamic>> categoriesData,
  ) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return categoriesData;

      // Fetch all distinct categories from past expenses
      final txResponse = await client
          .from('transactions')
          .select('category')
          .eq('user_id', userId)
          .eq('type', 'Expense');

      final List<dynamic> txData = txResponse as List<dynamic>;

      // Build a set of unique known categories (case-preserved)
      final Set<String> knownCategories = {};
      for (var tx in txData) {
        final cat = tx['category'] as String?;
        if (cat != null && cat.trim().isNotEmpty) {
          knownCategories.add(cat.trim());
        }
      }

      if (knownCategories.isEmpty) return categoriesData;

      // For each budget category, attempt correction
      for (var entry in categoriesData) {
        final String inputName = (entry['name'] as String? ?? '').trim();
        if (inputName.isEmpty) continue;

        // Skip if it's already an exact match (case-insensitive)
        if (knownCategories
            .any((k) => k.toLowerCase() == inputName.toLowerCase())) {
          // Normalise casing to match the known category
          final match = knownCategories.firstWhere(
              (k) => k.toLowerCase() == inputName.toLowerCase());
          entry['name'] = match;
          continue;
        }

        // Find closest match
        String? bestMatch;
        double bestSimilarity = 0.0;

        for (var known in knownCategories) {
          final similarity = _similarity(inputName, known);
          if (similarity > bestSimilarity) {
            bestSimilarity = similarity;
            bestMatch = known;
          }
        }

        if (bestMatch != null && bestSimilarity >= 0.6) {
          debugPrint(
            'AutoCorrect: "$inputName" → "$bestMatch" '
            '(similarity: ${(bestSimilarity * 100).toStringAsFixed(0)}%)',
          );
          entry['name'] = bestMatch;
        }
      }
    } catch (e) {
      debugPrint('BudgetMonitorService.autoCorrectCategories error: $e');
    }

    return categoriesData;
  }

  // ════════════════════════════════════════════════════════════════════════
  //  LEVENSHTEIN DISTANCE (pure Dart)
  // ════════════════════════════════════════════════════════════════════════

  /// Returns a value between 0.0 (completely different) and 1.0 (identical).
  static double _similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final distance = _levenshtein(a.toLowerCase(), b.toLowerCase());
    final maxLen = max(a.length, b.length);
    return 1.0 - (distance / maxLen);
  }

  /// Classic Levenshtein edit distance using O(min(m,n)) space.
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    // Ensure s is the shorter string for space optimisation
    if (s.length > t.length) {
      final temp = s;
      s = t;
      t = temp;
    }

    final sLen = s.length;
    final tLen = t.length;
    List<int> prev = List<int>.generate(sLen + 1, (i) => i);
    List<int> curr = List<int>.filled(sLen + 1, 0);

    for (int j = 1; j <= tLen; j++) {
      curr[0] = j;
      for (int i = 1; i <= sLen; i++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        curr[i] = min(
          min(curr[i - 1] + 1, prev[i] + 1),
          prev[i - 1] + cost,
        );
      }
      // Swap rows
      final temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[sLen];
  }

  // ════════════════════════════════════════════════════════════════════════
  //  3. TIMEZONE INITIALIZATION
  // ════════════════════════════════════════════════════════════════════════

  static bool _timezoneInitialized = false;

  /// Call once from main() or lazily before scheduling.
  static Future<void> initializeTimezone() async {
    if (_timezoneInitialized) return;
    tz.initializeTimeZones();
    try {
      final timezoneResult = await FlutterTimezone.getLocalTimezone();
      // flutter_timezone v5 returns TimezoneInfo; extract the IANA identifier
      String tzName = timezoneResult.toString();
      // If it's a TimezoneInfo object, parse out the identifier
      // Format: "TimezoneInfo(Asia/Calcutta, (locale: en_US, name: ...))"
      final match = RegExp(r'TimezoneInfo\(([^,]+)').firstMatch(tzName);
      if (match != null) {
        tzName = match.group(1)!.trim();
      }
      debugPrint('Device timezone resolved: $tzName');
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      debugPrint('Timezone lookup failed ($e), falling back to Asia/Kolkata');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
    _timezoneInitialized = true;
  }

  // ════════════════════════════════════════════════════════════════════════
  //  4. DAILY SPENT SUMMARY — SCHEDULED NOTIFICATION
  // ════════════════════════════════════════════════════════════════════════

  /// Notification ID reserved for the daily summary (different from budget = 0).
  static const int _dailySummaryNotificationId = 1001;

  /// Recalculates today's spending and (re-)schedules the daily summary
  /// notification at the user's preferred alert time.
  ///
  /// Call this:
  ///  - When the user saves notification settings.
  ///  - After every new expense transaction is inserted.
  ///
  /// **Android 16 (API 36) compliance:** Expects exact alarm permissions 
  /// to be checked by the UI before calling this.
  static Future<void> scheduleExactDailySummary() async {
    // ── 0. Ensure prerequisites ─────────────────────────────────
    await initializeTimezone();
    await _ensureNotificationsInitialized();

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    // ── 1. Read preferred alert time from SharedPreferences ────
    final prefs = await SharedPreferences.getInstance();
    final bool dailyEnabled = prefs.getBool('daily_spent') ?? false;
    if (!dailyEnabled) {
      // User has disabled daily summaries — cancel any pending one
      await _notificationsPlugin.cancel(id: _dailySummaryNotificationId);
      debugPrint('Daily summary disabled — cancelled.');
      return;
    }

    final String alertTimeStr = prefs.getString('alert_time') ?? '08:00';
    final parts = alertTimeStr.split(':');
    final int hour = int.tryParse(parts[0]) ?? 8;
    final int minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    // ── 2. Fetch today's expenses & generate summary ────────────
    // Wrapped in its own try-catch so a Supabase timeout can never
    // prevent the notification from being scheduled.
    String summaryBody =
        "Don't forget to review your daily expenses in FinTrack!";

    try {
      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).toIso8601String();
      final todayEnd =
          DateTime(now.year, now.month, now.day + 1).toIso8601String();

      final txResponse = await client
          .from('transactions')
          .select('amount, category')
          .eq('user_id', userId)
          .eq('type', 'Expense')
          .gte('created_at', todayStart)
          .lt('created_at', todayEnd);

      final List<dynamic> txData = txResponse as List<dynamic>;
      summaryBody = _generateDailySummary(txData);
    } catch (e) {
      // Supabase fetch or summary generation failed — use fallback
      debugPrint(
        'Daily summary data fetch failed ($e). '
        'Using fallback message.',
      );
    }

    // ── 3. GUARANTEED: Schedule the notification ────────────────
    // This block always executes, even if Supabase timed out above.
    try {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

      await _notificationsPlugin.cancel(id: _dailySummaryNotificationId);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'daily_summary_demo', // Unique channel ID
        'Daily Spending Summary',
        channelDescription:
            'AI-powered daily summary of your spending activity',
        importance: Importance.max, // Forced max for popup
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // ── Attempt exact alarm ──────────────────
      debugPrint('DEBUG: Device Timezone is ${tz.local.name}');
      debugPrint('DEBUG: Current TZ time is ${tz.TZDateTime.now(tz.local)}');
      debugPrint('DEBUG: Scheduling EXACTLY for $scheduledDate');
      
      try {
        await _notificationsPlugin.zonedSchedule(
          id: _dailySummaryNotificationId,
          title: '📊 FinTrack Daily Summary',
          body: summaryBody,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: null,
        );
        debugPrint(
          '✅ Daily summary (exact) scheduled for $scheduledDate — '
          '"$summaryBody"',
        );

        // Save to local Notification History dynamically
        await NotificationStorage.saveNotification(
          '📊 FinTrack Daily Summary',
          summaryBody,
          timestamp: scheduledDate,
          type: 'daily_summary',
        );

      } catch (exactAlarmError) {
        // ── Android 16 (API 36) residual exact alarm error catch ────
        debugPrint(
          '⚠️ EXACT ALARM ERROR: $exactAlarmError\n'
          '   Ensure the app has Alarms & Reminders permission granted.',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to schedule daily summary notification: $e');
    }
  }

  // ── Helper: generate the summary text ─────────────────────────────────
  static String _generateDailySummary(List<dynamic> txData) {
    if (txData.isEmpty) {
      const zeroMessages = [
        '🎉 Zero spending today — your wallet is happy!',
        '✨ No expenses logged today. Great discipline!',
        '💰 You didn\'t spend anything today. Keep it up!',
      ];
      return zeroMessages[DateTime.now().millisecond % zeroMessages.length];
    }

    double total = 0;
    final Map<String, double> categoryTotals = {};

    for (var tx in txData) {
      final double amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      final String category = (tx['category'] as String?) ?? 'Others';
      total += amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    // Find top category
    String topCategory = 'Others';
    double topAmount = 0;
    categoryTotals.forEach((cat, amt) {
      if (amt > topAmount) {
        topAmount = amt;
        topCategory = cat;
      }
    });

    final int count = txData.length;
    final String totalStr = total.toStringAsFixed(0);

    if (categoryTotals.length == 1) {
      return 'You spent ₹$totalStr today across $count '
          'transaction${count > 1 ? 's' : ''} — all on $topCategory.';
    }

    return 'You spent ₹$totalStr today across $count '
        'transaction${count > 1 ? 's' : ''}. '
        'Most went to $topCategory (₹${topAmount.toStringAsFixed(0)}).';
  }

  // ── Helper: next occurrence of HH:MM in local TZ ──────────────────────
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
