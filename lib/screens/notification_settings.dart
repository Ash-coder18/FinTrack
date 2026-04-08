import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';
import '../services/budget_monitor_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // ── Notification Plugin ───────────────────────────────────
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ── Toggle States ─────────────────────────────────────────
  bool _budgetAlerts = false;
  bool _dailySpent = false;


  bool _isSaving = false;
  bool _isLoading = true;

  // ── Preferred Alert Time ───────────────────────────────────
  TimeOfDay _alertTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadSettings();
    _requestPermissions(); // Request runtime permissions explicitly on open
  }

  Future<void> _initNotifications() async {
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
  }

  Future<void> _requestPermissions() async {
    // Android 13+ (API 33+) — POST_NOTIFICATIONS permission
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    // iOS
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // Parse stored alert time ("HH:mm")
    final parts = settings.alertTime.split(':');
    final int hour = int.tryParse(parts[0]) ?? 8;
    final int minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    setState(() {
      _budgetAlerts = prefs.getBool('budget_alerts_enabled') ?? false;
      _dailySpent = prefs.getBool('daily_summary_enabled') ?? false;
      _alertTime = TimeOfDay(hour: hour, minute: minute);
      _isLoading = false;
    });
  }

  Future<void> _saveToggleState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('budget_alerts_enabled', _budgetAlerts);
    await prefs.setBool('daily_summary_enabled', _dailySpent);
  }

  // ── Persistence & Scheduling ──────────────────────────────────
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await _saveToggleState();

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final String timeStr =
          '${_alertTime.hour.toString().padLeft(2, '0')}:${_alertTime.minute.toString().padLeft(2, '0')}';

      await settings.setNotificationSettings(_budgetAlerts, _dailySpent, timeStr);

      // Ensure notification permissions are granted before scheduling
      if (_dailySpent || _budgetAlerts) {
        // Enforce POST_NOTIFICATIONS permission
        final isNotificationGranted = await Permission.notification.request().isGranted;
        if (!isNotificationGranted) {
          _showSnackBar('You must allow notifications to use this feature', isError: true);
          return;
        }
        
        // Critical for Android 16 (API 36): Check Exact Alarm Permission
        if (_dailySpent) {
          final isExactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
          if (!isExactAlarmGranted) {
            // Permission missing, redirect user and skip scheduling
            await openAppSettings();
            _showSnackBar('Please allow Alarms & Reminders permission to get accurate summaries.', isError: true);
            return;
          }
        }
      }

      // Immediately (re-)schedule or cancel the daily summary notification
      await BudgetMonitorService.scheduleExactDailySummary();

      if (!mounted) return;
      final lang2 = settings.languageLabel;
      final t2 = AppTranslations.of(lang2);
      _showSnackBar(t2['settings_saved']!);
    } catch (e) {
      _showSnackBar('Something went wrong: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Time Picker ───────────────────────────────────────────────
  Future<void> _pickAlertTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alertTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _alertTime) {
      setState(() => _alertTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t['notification_settings']!,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Alert Preferences ──────────────────────
                  _buildSectionHeader(t['alert_preferences']!),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: Icons.warning_amber_rounded,
                    title: t['budget_exceed_alerts']!,
                    subtitle: t['budget_exceed_sub']!,
                    value: _budgetAlerts,
                    onChanged: (v) async {
                      setState(() => _budgetAlerts = v);
                      await _saveToggleState();
                      if (v) _requestPermissions();
                    },
                  ),
                  _buildToggleCard(
                    icon: Icons.today_outlined,
                    title: t['daily_spent_details']!,
                    subtitle: t['daily_spent_sub']!,
                    value: _dailySpent,
                    onChanged: (v) async {
                      setState(() => _dailySpent = v);
                      await _saveToggleState();
                      if (v) _requestPermissions();
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── Preferred Alert Time (visible when daily toggle is on) ──
                  if (_dailySpent) ...[
                    _buildSectionHeader(t['preferred_alert_time']!),
                    const SizedBox(height: 8),
                    Text(
                      t['alert_time_desc']!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimePicker(),
                    const SizedBox(height: 28),
                  ],

                  const SizedBox(height: 8),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ── Section Header ────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  // ── Toggle Card ───────────────────────────────────────────
  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ── Time Picker Card ──────────────────────────────────────
  Widget _buildTimePicker() {
    final formattedTime = _alertTime.format(context);
    return GestureDetector(
      onTap: _pickAlertTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: AppColors.primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedTime,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to change',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_rounded,
              color: AppColors.primaryBlue.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Save Button ───────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _saveSettings(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                AppTranslations.of(Provider.of<SettingsProvider>(context, listen: false).languageLabel)['save_settings']!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor:
            isError ? AppColors.expenseRed : AppColors.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
