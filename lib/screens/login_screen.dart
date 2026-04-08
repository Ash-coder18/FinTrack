import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';
import 'forgot_password_screen.dart';
import '../widgets/theme_aware_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignIn = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Map<String, String> get _t {
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
    return AppTranslations.of(lang);
  }

  Future<void> _handleAuth() async {
    final t = _t;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(t['fill_all_fields']!);
      return;
    }

    if (!_isSignIn) {
      final confirm = _confirmPasswordController.text.trim();
      if (password != confirm) {
        _showError(t['passwords_no_match']!);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignIn) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (!mounted) return;
        // Show success message and switch to Sign In tab
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t['signup_success']!,
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() => _isSignIn = true);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(t['something_went_wrong']!);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final t = _t;
    setState(() => _isLoading = true);

    try {
      const webClientId = '998310410469-tg01qtfh648rc2skr7o7for4n7aqu1lv.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;
      final accessToken = googleAuth?.accessToken;
      final idToken = googleAuth?.idToken;

      if (idToken == null) {
        // User aborted sign in or failure occurred
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      _showError(t['something_went_wrong'] ?? e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false, // Let the white container flow to the bottom edge
        child: Column(
          children: [
            // Top Half: Blue Background with Logo
            Expanded(
              flex: 3,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: const ThemeAwareLogo(height: 60),
                  ),
                ),
              ),
            ),
            
            // Bottom Half: White Container with Form
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: _buildFormContent(t),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(Map<String, String> t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Custom Toggle Switch
          _buildToggleSwitch(t),
          const SizedBox(height: 40),
          
          // Form Fields
          _buildTextField(hintText: t['email_hint']!, controller: _emailController),
          const SizedBox(height: 24),
          _buildTextField(hintText: _isSignIn ? t['password_hint']! : t['enter_password']!, obscureText: true, controller: _passwordController),
          
          if (!_isSignIn) ...[
            const SizedBox(height: 24),
            _buildTextField(hintText: t['confirm_password']!, obscureText: true, controller: _confirmPasswordController),
          ],

          if (_isSignIn) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                t['forgot_password']!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontFamily: 'SF Pro',
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Main Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _isSignIn ? t['login']! : t['sign_up']!,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontFamily: 'SF Pro',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 32),
          
          // OR Divider
          Text(
            t['or']!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 32),

          // Google Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/google_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey), // Fallback if image isn't configured yet
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t['continue_google']!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontFamily: 'SF Pro',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(Map<String, String> t) {
    return Container(
      width: 240,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF8D8D8D), // grey matching design
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _isSignIn ? 0 : 120, // Slider shifts based on state
            child: Container(
              width: 120,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary, // Selected is blue
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSignIn = true;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      t['sign_in']!,
                      style: TextStyle(
                        color: _isSignIn ? AppColors.white : AppColors.white,
                        fontSize: 16,
                        fontFamily: 'SF Pro',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSignIn = false;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      t['sign_up']!,
                      style: TextStyle(
                        color: AppColors.white, // In the design, both texts are white on grey/blue
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
        ],
      ),
    );
  }

  Widget _buildTextField({required String hintText, bool obscureText = false, TextEditingController? controller}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color ?? (isDark ? Colors.white : Colors.black87),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
        labelText: hintText,
        labelStyle: TextStyle(
          color: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.focused) ? AppColors.primary : (isDark ? Colors.grey.shade400 : Colors.grey)),
          fontFamily: 'SF Pro',
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontFamily: 'SF Pro',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      ),
    );
  }
}
