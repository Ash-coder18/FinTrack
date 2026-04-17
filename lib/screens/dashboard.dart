import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';
import 'add_transaction_screen.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/theme_aware_logo.dart';
import '../widgets/adaptive_animated_background.dart';
import 'transactions_view.dart';
import 'ai_chat_view.dart';
import 'profile_view.dart';
import 'notification_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<HomeViewState> _homeKey = GlobalKey();
  String? _avatarUrl;
  late final StreamSubscription<AuthState> _authSubscription;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();

    // Listen for auth metadata changes (e.g. avatar updated in Profile tab)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      _loadUserAvatar();
    });

    _pages = [
      HomeView(key: _homeKey),
      const TransactionsView(),
      const AiChatView(),
      const ProfileView(),
    ];
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _loadUserAvatar() {
    final user = Supabase.instance.client.auth.currentUser;
    final url = user?.userMetadata?['avatar_url'] as String?;
    if (mounted) {
      setState(() => _avatarUrl = url);
    }
  }

  /// Called from the drawer after a Settings reset to refresh dashboard data.
  void refreshHomeData() {
    _homeKey.currentState?.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AdaptiveAnimatedBackground(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ).copyWith(bottom: 12),
                child: _buildHeader(),
              ),
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: _pages),
              ),
            ],
          ),
        ),
        floatingActionButton: isKeyboardOpen
            ? null
            : FloatingActionButton(
                shape: const CircleBorder(),
                backgroundColor: AppColors.primary,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const AddTransactionScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.easeOutCubic;

                            var tween = Tween(
                              begin: begin,
                              end: end,
                            ).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                    ),
                  );
                  _homeKey.currentState?.refreshData();
                },
                child: const Icon(Icons.add, color: AppColors.white, size: 32),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        endDrawer: const CustomDrawer(),
        bottomNavigationBar: _buildBottomNavigationBar(t),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [const ThemeAwareLogo(height: 38)]),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationHistoryScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.notifications_none_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
            ),
            const SizedBox(width: 4),
            Builder(
              builder: (ctx) => IconButton(
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                icon: Icon(
                  Icons.menu_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(Map<String, String> t) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0.0,
        clipBehavior: Clip.antiAlias,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home, t['home']!, 0),
              _buildNavItem(Icons.swap_horiz, t['transaction']!, 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.chat_bubble_outline, t['ai_chat']!, 2),
              _buildProfileNavItem(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index, {
    bool isIconOnly = false,
  }) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _loadUserAvatar();
      },
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isIconOnly ? 30 : 26),
            if (!isIconOnly) const SizedBox(height: 4),
            if (!isIconOnly)
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem() {
    final bool isSelected = _selectedIndex == 3;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = 3;
        });
        _loadUserAvatar();
      },
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _avatarUrl != null
                ? CircleAvatar(
                    radius: isSelected ? 20 : 18,
                    backgroundImage: NetworkImage(_avatarUrl!),
                    backgroundColor: const Color(0xFFBDBDBD),
                  )
                : Icon(
                    Icons.person_outline,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 30,
                  ),
          ],
        ),
      ),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late Future<List<dynamic>> _dashboardDataFuture;
  int _touchedIndex = -1;
  late AnimationController _chartAnimController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimController,
      curve: Curves.easeInOutCubic,
    );
    refreshData();
  }

  @override
  void dispose() {
    _chartAnimController.dispose();
    super.dispose();
  }

  void refreshData() {
    _chartAnimController.reset();
    setState(() {
      _dashboardDataFuture = Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .then((data) {
            if (mounted) {
              _chartAnimController.forward();
            }
            return data;
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    return FutureBuilder<List<dynamic>>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${t['error_prefix']!}${snapshot.error}',
              style: const TextStyle(
                color: AppColors.error,
                fontFamily: 'Inter',
              ),
            ),
          );
        }

        double totalIncome = 0.0;
        double totalExpense = 0.0;
        final List<dynamic> allTransactions = snapshot.data ?? [];
        Map<String, double> expenseByCategory = {};

        for (var tx in allTransactions) {
          final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          if (tx['type'] == 'Income') {
            totalIncome += amt;
          } else if (tx['type'] == 'Expense') {
            totalExpense += amt;
            final category = tx['category'] as String? ?? t['others']!;
            expenseByCategory[category] =
                (expenseByCategory[category] ?? 0.0) + amt;
          }
        }

        var sortedExpenses = expenseByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        List<MapEntry<String, double>> top5Expenses = [];
        double othersAmount = 0.0;

        for (int i = 0; i < sortedExpenses.length; i++) {
          if (i < 4) {
            top5Expenses.add(sortedExpenses[i]);
          } else {
            othersAmount += sortedExpenses[i].value;
          }
        }

        if (othersAmount > 0) {
          top5Expenses.add(MapEntry(t['others']!, othersAmount));
        }

        String topCategoryName = top5Expenses.isNotEmpty
            ? top5Expenses.first.key
            : t['no_expenses']!;

        double availableBalance = totalIncome - totalExpense;
        List<dynamic> recentTransactions = allTransactions.take(4).toList();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(
                  availableBalance,
                  totalIncome,
                  totalExpense,
                  t,
                ),
                const SizedBox(height: 30),
                _buildChartSection(top5Expenses, topCategoryName, t),
                const SizedBox(height: 30),
                _buildRecentTransactions(recentTransactions, t),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(
    double availableBalance,
    double totalIncome,
    double totalExpense,
    Map<String, String> t,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB), // Royal Blue
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: WaveWidget(
                config: CustomConfig(
                  gradients: [
                    [const Color(0x33FFFFFF), const Color(0x11FFFFFF)],
                    [const Color(0x44FFFFFF), const Color(0x22FFFFFF)],
                    [const Color(0x55FFFFFF), const Color(0x00FFFFFF)],
                  ],
                  durations: [35000, 19440, 10800],
                  heightPercentages: [0.60, 0.65, 0.70],
                  gradientBegin: Alignment.bottomLeft,
                  gradientEnd: Alignment.topRight,
                ),
                waveAmplitude: 0,
                backgroundColor: Colors.transparent,
                size: const Size(double.infinity, double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['available_balance']!,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      currencyFormat.format(availableBalance),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 32,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildIncomeExpenseCard(
                          t['expense']!,
                          currencyFormat.format(totalExpense),
                          AppColors.chartRose,
                          Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildIncomeExpenseCard(
                          t['income']!,
                          currencyFormat.format(totalIncome),
                          AppColors.chartGreen,
                          Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseCard(
    String title,
    String amount,
    Color contentColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Glassmorphism base
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: contentColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(
    List<MapEntry<String, double>> chartData,
    String topCategoryName,
    Map<String, String> t,
  ) {
    Color getCategoryColor(String category, int index) {
      // VIBGYOR Sequence
      final List<Color> chartColors = [
        AppColors.chartViolet, // V
        AppColors.chartIndigo, // I
        AppColors.chartBlue, // B
        AppColors.chartGreen, // G
        AppColors.chartYellow, // Y
        AppColors.chartOrange, // O
        AppColors.chartRed, // R
      ];
      return chartColors[index % chartColors.length];
    }

    List<Widget> legendItems = [];
    double totalValue = 0.0;

    if (chartData.isEmpty) {
      totalValue = 1.0;
      legendItems.add(
        _buildLegendItem(t['no_expenses']!, AppColors.greyMedium),
      );
    } else {
      for (int i = 0; i < chartData.length; i++) {
        totalValue += chartData[i].value;
        legendItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildLegendItem(
              chartData[i].key,
              getCategoryColor(chartData[i].key, i),
            ),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      height: 230,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // FlChart Pie Chart
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                List<PieChartSectionData> pieSections = [];
                final double animV = _chartAnimation.value;
                final double currentSweepTotal = totalValue * animV;
                double accumulated = 0.0;

                if (chartData.isEmpty) {
                  pieSections.add(
                    PieChartSectionData(
                      color: AppColors.greyMedium,
                      value: currentSweepTotal > 0 ? currentSweepTotal : 0.0001,
                      title: '',
                      radius: 20.0,
                    ),
                  );
                } else {
                  for (int i = 0; i < chartData.length; i++) {
                    final targetVal = chartData[i].value;
                    final color = getCategoryColor(chartData[i].key, i);
                    final isTouched = i == _touchedIndex;
                    final radius = isTouched ? 28.0 : 20.0;

                    double visibleVal = 0.0;
                    if (currentSweepTotal > accumulated) {
                      visibleVal = math.min(
                        currentSweepTotal - accumulated,
                        targetVal,
                      );
                    }

                    if (visibleVal > 0) {
                      pieSections.add(
                        PieChartSectionData(
                          color: color,
                          value: visibleVal,
                          title: '',
                          radius: radius,
                        ),
                      );
                    }
                    accumulated += targetVal;
                  }
                }

                final double remaining = totalValue - currentSweepTotal;
                if (remaining > 0) {
                  pieSections.add(
                    PieChartSectionData(
                      color: Colors.transparent,
                      value: remaining,
                      title: '',
                      radius: 20.0,
                    ),
                  );
                }

                if (pieSections.isEmpty) {
                  pieSections.add(
                    PieChartSectionData(
                      color: Colors.transparent,
                      value: 1.0,
                      title: '',
                      radius: 20.0,
                    ),
                  );
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  final touchIdx = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                  if (chartData.isNotEmpty &&
                                      touchIdx < chartData.length) {
                                    _touchedIndex = touchIdx;
                                  } else {
                                    _touchedIndex = -1;
                                  }
                                });
                              },
                        ),
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: pieSections,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        if (_touchedIndex >= 0 &&
                            _touchedIndex < chartData.length) {
                          final double total = chartData.fold(
                            0.0,
                            (sum, item) => sum + item.value,
                          );
                          final double val = chartData[_touchedIndex].value;
                          final double percentage = total > 0
                              ? (val / total * 100)
                              : 0;
                          return Text(
                            '${percentage.toStringAsFixed(1)}%',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: getCategoryColor(
                                chartData[_touchedIndex].key,
                                _touchedIndex,
                              ),
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }
                        return Text(
                          t['expense']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 30),
          // Legend
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: legendItems.isNotEmpty
                  ? legendItems
                  : const [SizedBox()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontFamily: 'Inter',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    List<dynamic> transactions,
    Map<String, String> t,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t['recent_transaction']!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: transactions.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          t['no_recent_txn']!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ]
                : transactions.map((tx) {
                    final isIncome = tx['type'] == 'Income';
                    final color = isIncome
                        ? AppColors.success
                        : AppColors.error;
                    final title =
                        tx['category'] as String? ??
                        (isIncome ? t['income']! : '—');
                    final amountVal = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                    final amountText = isIncome
                        ? '+₹ ${amountVal.toStringAsFixed(2)}'
                        : '-₹ ${amountVal.toStringAsFixed(2)}';
                    final methodText =
                        tx['method'] as String? ?? (isIncome ? 'Direct' : '—');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Text(
                                  amountText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                methodText,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ),
        const SizedBox(height: 40), // extra padding for bottom nav space
      ],
    );
  }
}
