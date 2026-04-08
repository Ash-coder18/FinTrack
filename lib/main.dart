import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/budget_monitor_service.dart';

import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/financial_awareness.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard.dart';
import 'screens/notification_settings.dart';
import 'screens/settings_screen.dart';
import 'screens/update_password_screen.dart';

// ── Top-level globals ──────────────────────────────────────────
late final SupabaseClient supabase;

// ── Entrypoint ─────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://aywjdbtumkpnzixieltt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF5d2pkYnR1bWtwbnppeGllbHR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MjM4MTIsImV4cCI6MjA5MDE5OTgxMn0.nXyHGdoQxtTBoD36mTwLa0y848dE-XLPePu2tUJB02w',
  );
  supabase = Supabase.instance.client;

  // Initialize timezone database for zonedSchedule notifications
  await BudgetMonitorService.initializeTimezone();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(FinTrackApp(settingsProvider: settingsProvider));
}

// ── Root Widget ────────────────────────────────────────────────
class FinTrackApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  const FinTrackApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: settingsProvider,
      child: Builder(
        builder: (providerContext) {
          final settings = providerContext.watch<SettingsProvider>();
          return MaterialApp(
            title: 'FinTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,

            // AuthGate handles initial routing declaratively.
            // Named routes still work for in-app navigation.
            home: const AuthGate(),
            routes: {
              '/onboarding': (_) => const FinancialAwarenessScreen(),
              '/login': (_) => const LoginScreen(),
              '/dashboard': (_) => const DashboardScreen(),
              '/notifications': (_) => const NotificationSettingsScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/update-password': (_) => const UpdatePasswordScreen(),
            },
          );
        },
      ),
    );
  }
}

// ── AuthGate — declarative routing based on auth state ─────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    // Registered ONCE — uses Navigator.push safely since AuthGate
    // lives inside MaterialApp and has a valid Navigator context.
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const UpdatePasswordScreen()),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // 2. User has an active session → go to dashboard
    final session = supabase.auth.currentSession;
    if (session != null) {
      return const DashboardScreen();
    }

    // 3. No session → onboarding / login
    return const FinancialAwarenessScreen();
  }
}
