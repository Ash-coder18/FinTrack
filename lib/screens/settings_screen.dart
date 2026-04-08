import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';
import 'login_screen.dart';
import 'dashboard.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Preference State ──────────────────────────────────────
  String _theme = 'System';
  String _language = 'English';

  bool _isLoading = true;
  int? _preferenceId;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // ── Fetch preferences from Supabase ───────────────────────
  Future<void> _loadPreferences() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await client
          .from('app_preferences')
          .select()
          .eq('user_id', userId)
          .limit(1);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isNotEmpty && mounted) {
        final p = data.first;
        final settingsProvider =
            Provider.of<SettingsProvider>(context, listen: false);

        setState(() {
          _preferenceId = p['id'] as int?;
          _theme = p['theme'] as String? ?? 'System';
          _language = p['language'] as String? ?? 'English';
          _isLoading = false;
        });

        // Sync provider with DB values
        settingsProvider.setTheme(_theme);
        settingsProvider.setLanguage(_language);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Auto-save a single field to Supabase ──────────────────
  Future<void> _saveField(String field, dynamic value) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final payload = {'user_id': userId, field: value};

      if (_preferenceId != null) {
        await client
            .from('app_preferences')
            .update({field: value}).eq('id', _preferenceId!);
      } else {
        final inserted = await client
            .from('app_preferences')
            .insert(payload)
            .select()
            .single();
        _preferenceId = inserted['id'] as int?;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e',
              style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Reset Dialogs + Supabase Actions ──────────────────────
  Future<bool?> _showResetDialog(String title, String message,
      {bool isDestructive = false, String? confirmText}) {
    final t = AppTranslations.of(_language);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        content: Text(message,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t['cancel']!,
                style: const TextStyle(
                    fontFamily: 'Inter', color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText ?? (isDestructive ? t['wipe_all']! : t['reset']!),
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: isDestructive ? AppColors.error : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetBudgets() async {
    final confirmed = await _showResetDialog(
      'Reset Budgets',
      'Reset total monthly budget to zero?',
    );
    if (confirmed != true || !mounted) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('budgets')
          .update({'total_budget': 0, 'categories_data': []}).eq('user_id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Budget reset',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Failed: $e');
    }
  }

  Future<void> _resetTransactions() async {
    final confirmed = await _showResetDialog(
      'Reset Transactions',
      'Delete all transaction history?',
    );
    if (confirmed != true || !mounted) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('transactions')
          .delete()
          .eq('user_id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transactions cleared',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Failed: $e');
    }
  }

  Future<void> _masterReset() async {
    final confirmed = await _showResetDialog(
      'Master Reset',
      'WARNING: This will wipe all your transactions, custom categories, and budgets. Continue?',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final client = Supabase.instance.client;

      // Delete transactions
      await client.from('transactions').delete().eq('user_id', userId);

      // Reset total_budget to 0 and clear categories_data
      await client
          .from('budgets')
          .update({'total_budget': 0, 'categories_data': []}).eq('user_id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All data wiped',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Failed: $e');
    }
  }

  Future<void> _logout() async {
    final t = AppTranslations.of(_language);
    final confirmed = await _showResetDialog(
      t['log_out'] ?? 'Log Out',
      'Are you sure you want to log out?',
      confirmText: t['log_out'] ?? 'Log Out',
    );
    if (confirmed != true || !mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Logout Failed: $e');
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Section Header Builder ─────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 1.2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ── Styled Dropdown ────────────────────────────────────────
  Widget _dropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurface)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: cs.onSurfaceVariant),
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface),
            dropdownColor: cs.surface,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // ── Switch Tile ────────────────────────────────────────────
  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurface)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: cs.onSurfaceVariant)),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  // ── Danger / Reset Tile ────────────────────────────────────
  Widget _resetTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isMasterReset = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isMasterReset
              ? AppColors.error.withAlpha(25)
              : AppColors.warning.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: isMasterReset ? AppColors.error : AppColors.warning,
            size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: isMasterReset ? FontWeight.w600 : FontWeight.w500,
              color: isMasterReset ? AppColors.error : cs.onSurface)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: cs.onSurfaceVariant, size: 22),
      onTap: onTap,
    );
  }

  // ── Navigation Tile (About & Support) ──────────────────────
  Widget _navTile({
    required IconData icon,
    required String title,
    String? trailing,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurface)),
      trailing: trailing != null
          ? Text(trailing,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: cs.onSurfaceVariant))
          : Icon(Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant, size: 22),
      onTap: onTap,
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTranslations.of(_language);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t['settings']!,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // ─────────────────── APPEARANCE ───────────────────
                _sectionHeader(t['appearance']!),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    return _card(children: [
                      _dropdownTile(
                        icon: Icons.palette_outlined,
                        title: t['theme']!,
                        value: settings.themeLabel,
                        items: const ['Light', 'Dark', 'System'],
                        onChanged: (v) {
                          if (v != null) {
                            settings.setTheme(v);
                            setState(() => _theme = v);
                            _saveField('theme', v);
                          }
                        },
                      ),
                      const Divider(indent: 76, endIndent: 20, height: 1),
                      _dropdownTile(
                        icon: Icons.language_rounded,
                        title: t['language']!,
                        value: settings.languageLabel,
                        items: const ['English', 'Tamil'],
                        onChanged: (v) {
                          if (v != null) {
                            settings.setLanguage(v);
                            setState(() => _language = v);
                            _saveField('language', v);
                          }
                        },
                      ),
                    ]);
                  },
                ),



                // ─────────────────── RESET OPTIONS ───────────────
                _sectionHeader(t['reset_options']!),
                _card(children: [
                  _resetTile(
                    icon: Icons.pie_chart_outline_rounded,
                    title: t['reset_budgets']!,
                    onTap: _resetBudgets,
                  ),
                  const Divider(indent: 76, endIndent: 20, height: 1),
                  _resetTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Reset Transactions',
                    onTap: _resetTransactions,
                  ),
                  const Divider(indent: 76, endIndent: 20, height: 1),
                  _resetTile(
                    icon: Icons.warning_amber_rounded,
                    title: t['master_reset']!,
                    onTap: _masterReset,
                    isMasterReset: true,
                  ),
                ]),

                // ─────────────────── ABOUT ─────────────
                _sectionHeader(t['about']!),
                _card(children: [
                  _navTile(
                    icon: Icons.info_outline_rounded,
                    title: t['app_version']!,
                    trailing: 'v1.0.0',
                  ),
                ]),

                const SizedBox(height: 20),
                
                // ─────────────────── LOG OUT ─────────────
                _card(children: [
                  _resetTile(
                    icon: Icons.logout_rounded,
                    title: t['log_out'] ?? 'Log Out',
                    onTap: _logout,
                    isMasterReset: true, // Reuses the red error styling
                  ),
                ]),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // ── Rounded Card Wrapper ───────────────────────────────────
  Widget _card({required List<Widget> children}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withAlpha(120), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
