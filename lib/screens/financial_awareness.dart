import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';

class FinancialAwarenessScreen extends StatefulWidget {
  const FinancialAwarenessScreen({super.key});

  @override
  State<FinancialAwarenessScreen> createState() => _FinancialAwarenessScreenState();
}

class _FinancialAwarenessScreenState extends State<FinancialAwarenessScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);

    final List<Map<String, String>> onboardingData = [
      {
        'title': t['onboarding_title_1']!,
        'subtitle': t['onboarding_sub_1']!,
        'imagePath': 'assets/images/onboarding1.png',
      },
      {
        'title': t['onboarding_title_2']!,
        'subtitle': t['onboarding_sub_2']!,
        'imagePath': 'assets/images/onboarding2.png',
      },
      {
        'title': t['onboarding_title_3']!,
        'subtitle': t['onboarding_sub_3']!,
        'imagePath': 'assets/images/onboarding3.png',
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPageContent(
                    title: onboardingData[index]['title']!,
                    subtitle: onboardingData[index]['subtitle']!,
                    imagePath: onboardingData[index]['imagePath']!,
                    pageIndex: index,
                    totalPages: onboardingData.length,
                  );
                },
              ),
            ),
            _buildBottomControls(t, onboardingData.length),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent({
    required String title,
    required String subtitle,
    required String imagePath,
    required int pageIndex,
    required int totalPages,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Image.asset(
            imagePath,
            height: 280,
            fit: BoxFit.contain,
          ),
          const Spacer(flex: 1),
          // Dot Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => _buildDotIndicator(index),
            ),
          ),
          const SizedBox(height: 32),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    bool isCurrent = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 24,
      decoration: BoxDecoration(
        color: isCurrent ? Theme.of(context).colorScheme.onSurface : AppColors.greyMedium,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildBottomControls(Map<String, String> t, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => _onNextPressed(totalPages),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Text(
            t['next']!,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }


}
