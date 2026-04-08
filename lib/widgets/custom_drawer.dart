import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';
import '../screens/login_screen.dart';
import '../screens/set_budget_screen.dart';
import '../screens/monthly_report_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/dashboard.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  // ── State ───────────────────────────────────────────────
  String? _avatarUrl;
  String _fullName = 'User';
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Stay in sync with profile picture / name updates
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final meta = user.userMetadata;
    if (mounted) {
      setState(() {
        _avatarUrl = meta?['avatar_url'] as String?;
        _fullName = (meta?['full_name'] as String?)?.isNotEmpty == true
            ? meta!['full_name'] as String
            : 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Close button ──────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 12),
                child: IconButton(
                  icon: Icon(Icons.close, size: 28, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // ── Profile ───────────────────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                image: _avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_avatarUrl!),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: _avatarUrl == null
                  ? const Icon(Icons.person, size: 48, color: AppColors.white)
                  : null,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _fullName,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(indent: 24, endIndent: 24),

            // ── Menu items ────────────────────────────────
            _buildMenuItem(Icons.bar_chart_outlined, t['monthly_reports']!, onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MonthlyReportScreen()));
            }),
            _buildMenuItem(Icons.account_balance_wallet_outlined, t['set_budget']!, onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SetBudgetScreen()));
            }),
            _buildMenuItem(Icons.edit_notifications_outlined, t['notification_settings'] ?? 'Notification Settings', onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications');
            }),
            _buildMenuItem(Icons.help_outline, t['help_support_drawer']!, onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
            }),
            _buildMenuItem(Icons.settings_outlined, t['settings']!, onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),

            const SizedBox(height: 16),
            const Divider(indent: 24, endIndent: 24),



            // ── Push logout to bottom ─────────────────────
            const Spacer(),

            // ── Log out ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Log Out',
                            style: TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.w600, fontSize: 18)),
                        content: Text('Are you sure you want to log out?',
                            style: TextStyle(fontFamily: 'SF Pro', fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(t['cancel'] ?? 'Cancel',
                                style: TextStyle(fontFamily: 'SF Pro', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                          TextButton(
                            onPressed: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (!context.mounted) return;
                              Navigator.pop(dialogContext); // Close dialog
                              Navigator.pop(context); // Close drawer
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                            child: Text(
                              t['log_out'] ?? 'Log Out',
                              style: const TextStyle(
                                fontFamily: 'SF Pro',
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    t['log_out']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF Pro',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'SF Pro',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }

}
