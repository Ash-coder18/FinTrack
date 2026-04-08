import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  late Future<List<dynamic>> _transactionsFuture;
  bool _isExporting = false;

  // ── State for interactive drill-down ─────────────────────────────────
  String? _selectedDay; // e.g. 'Mon', 'Sat' — null means nothing selected
  List<MapEntry<String, double>> _selectedDayCategoryData = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  void _fetchTransactions() {
    setState(() {
      _transactionsFuture = Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
          .order('created_at', ascending: false);
    });
  }

  // ── Weekly expense totals (unchanged logic) ──────────────────────────
  List<Map<String, dynamic>> _processWeeklyExpenses(List<dynamic> allTransactions) {
    final now = DateTime.now();
    final mostRecentMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    Map<String, double> weekExpenses = {
      'Mon': 0.0, 'Tue': 0.0, 'Wed': 0.0,
      'Thu': 0.0, 'Fri': 0.0, 'Sat': 0.0, 'Sun': 0.0,
    };

    for (var tx in allTransactions) {
      if (tx['type'] == 'Expense') {
        final date = DateTime.parse(tx['created_at']);
        if (!date.isBefore(mostRecentMonday)) {
          final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          switch (date.weekday) {
            case DateTime.monday:    weekExpenses['Mon'] = (weekExpenses['Mon'] ?? 0) + amt; break;
            case DateTime.tuesday:   weekExpenses['Tue'] = (weekExpenses['Tue'] ?? 0) + amt; break;
            case DateTime.wednesday: weekExpenses['Wed'] = (weekExpenses['Wed'] ?? 0) + amt; break;
            case DateTime.thursday:  weekExpenses['Thu'] = (weekExpenses['Thu'] ?? 0) + amt; break;
            case DateTime.friday:    weekExpenses['Fri'] = (weekExpenses['Fri'] ?? 0) + amt; break;
            case DateTime.saturday:  weekExpenses['Sat'] = (weekExpenses['Sat'] ?? 0) + amt; break;
            case DateTime.sunday:    weekExpenses['Sun'] = (weekExpenses['Sun'] ?? 0) + amt; break;
          }
        }
      }
    }

    return [
      {'day': 'Mon', 'value': weekExpenses['Mon']},
      {'day': 'Tue', 'value': weekExpenses['Tue']},
      {'day': 'Wed', 'value': weekExpenses['Wed']},
      {'day': 'Thu', 'value': weekExpenses['Thu']},
      {'day': 'Fri', 'value': weekExpenses['Fri']},
      {'day': 'Sat', 'value': weekExpenses['Sat']},
      {'day': 'Sun', 'value': weekExpenses['Sun']},
    ];
  }

  // ── Compute per-day category breakdown ───────────────────────────────
  void _onBarTapped(String day, List<dynamic> allTransactions) {
    // Map weekday abbreviation → DateTime.weekday constant
    const dayToWeekday = {
      'Mon': DateTime.monday,
      'Tue': DateTime.tuesday,
      'Wed': DateTime.wednesday,
      'Thu': DateTime.thursday,
      'Fri': DateTime.friday,
      'Sat': DateTime.saturday,
      'Sun': DateTime.sunday,
    };

    final now = DateTime.now();
    final mostRecentMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final targetWeekday = dayToWeekday[day]!;

    final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
    final t = AppTranslations.of(lang);

    Map<String, double> categoryMap = {};

    for (var tx in allTransactions) {
      if (tx['type'] == 'Expense') {
        final date = DateTime.parse(tx['created_at']);
        if (!date.isBefore(mostRecentMonday) && date.weekday == targetWeekday) {
          final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final category = tx['category'] as String? ?? t['others']!;
          categoryMap[category] = (categoryMap[category] ?? 0.0) + amt;
        }
      }
    }

    // Sort descending and cap at 4 + Others (same logic as Dashboard)
    var sorted = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<MapEntry<String, double>> top = [];
    double othersAmount = 0.0;

    for (int i = 0; i < sorted.length; i++) {
      if (i < 4) {
        top.add(sorted[i]);
      } else {
        othersAmount += sorted[i].value;
      }
    }
    if (othersAmount > 0) {
      top.add(MapEntry(t['others']!, othersAmount));
    }

    setState(() {
      // Tapping the same bar again deselects it
      if (_selectedDay == day) {
        _selectedDay = null;
        _selectedDayCategoryData = [];
      } else {
        _selectedDay = day;
        _selectedDayCategoryData = top;
      }
    });
  }

  // ── CSV generation (unchanged) ──────────────────────────────────────
  Future<String> _generateCsvContent() async {
    final transactions = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    List<List<dynamic>> csvData = [
      ['Date', 'Time', 'Category', 'Amount', 'Type', 'Payment Mode', 'Notes']
    ];

    for (var tx in transactions) {
      final dt = DateTime.parse(tx['created_at']);
      final date = DateFormat('yyyy-MM-dd').format(dt);
      final time = DateFormat('HH:mm').format(dt);
      csvData.add([
        date,
        time,
        tx['category'] ?? '-',
        tx['amount']?.toString() ?? '0.0',
        tx['type'] ?? '-',
        tx['method'] ?? '-',
        tx['notes'] ?? ''
      ]);
    }

    return const CsvEncoder().convert(csvData);
  }

  void _showExportSheet() {
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
    final t = AppTranslations.of(lang);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t['export_report']!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.primary),
                title: Text(AppTranslations.of(Provider.of<SettingsProvider>(context, listen: false).languageLabel)['share_report']!, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                subtitle: Text(AppTranslations.of(Provider.of<SettingsProvider>(context, listen: false).languageLabel)['share_report_sub']!, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _shareReport();
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: AppColors.success),
                title: Text(AppTranslations.of(Provider.of<SettingsProvider>(context, listen: false).languageLabel)['save_to_device']!, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                subtitle: Text(AppTranslations.of(Provider.of<SettingsProvider>(context, listen: false).languageLabel)['save_to_device_sub']!, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _saveToDevice();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareReport() async {
    setState(() => _isExporting = true);
    try {
      final csvContent = await _generateCsvContent();

      final directory = await getTemporaryDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String path = '${directory.path}/FinTrack_Report_$timestamp.csv';

      final File file = File(path);
      await file.writeAsString(csvContent);

      if (!mounted) return;

      await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: 'Here is your FinTrack Report!'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share report: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveToDevice() async {
    setState(() => _isExporting = true);
    try {
      final csvContent = await _generateCsvContent();
      final Uint8List bytes = Uint8List.fromList(utf8.encode(csvContent));

      await FileSaver.instance.saveAs(
        name: 'FinTrack_Report_${DateTime.now().millisecondsSinceEpoch}',
        fileExtension: 'csv',
        bytes: bytes,
        mimeType: MimeType.other,
      );

      if (!mounted) return;
      final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t = AppTranslations.of(lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['report_saved']!, style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save report: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading report data',
                  style: const TextStyle(color: AppColors.error, fontFamily: 'Inter'),
                ),
              );
            }

            final List<dynamic> transactions = snapshot.data ?? [];
            final barData = _processWeeklyExpenses(transactions);

            // Use a Column layout so the button is pinned to the bottom
            return Column(
              children: [
                // ── Scrollable chart area ──────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['monthly_report']!,
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildBarChart(barData, transactions),

                        // ── Conditional Pie Chart ────────────────────
                        if (_selectedDay != null) ...[
                          const SizedBox(height: 24),
                          _buildDayBreakdownPieChart(t),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Bottom-pinned Download Button ──────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isExporting ? null : _showExportSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isExporting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                            )
                          : Text(
                              t['download_report']!,
                              style: const TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BAR CHART (now tappable)
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildBarChart(List<Map<String, dynamic>> barData, List<dynamic> transactions) {
    final cs = Theme.of(context).colorScheme;
    double maxValue = 0;
    for (var item in barData) {
      if (item['value'] > maxValue) maxValue = item['value'];
    }
    if (maxValue == 0) maxValue = 100;

    final double upperBound = ((maxValue / 100).ceil() * 100).toDouble();
    const double chartHeight = 260.0;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y-axis labels
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(upperBound.toStringAsFixed(0), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  Text((upperBound * 0.75).toStringAsFixed(0), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  Text((upperBound * 0.50).toStringAsFixed(0), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  Text((upperBound * 0.25).toStringAsFixed(0), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  Text('0', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
              const SizedBox(width: 8),
              // Bars
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: barData.map((item) {
                    final String day = item['day'];
                    final double barHeight = (item['value'] / upperBound) * chartHeight;
                    final bool isSelected = _selectedDay == day;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onBarTapped(day, transactions),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          height: barHeight < 4 ? 4 : barHeight, // minimum tap target
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentPurple
                                : AppColors.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.accentPurple.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Baseline
        Container(
          height: 1,
          color: AppColors.greyMedium,
          margin: const EdgeInsets.only(left: 32),
        ),
        // X-axis labels
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Row(
                children: barData.map((item) {
                  final bool isSelected = _selectedDay == item['day'];
                  return Expanded(
                    child: Text(
                      item['day'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.accentPurple
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  PIE CHART – exact replica of the Dashboard doughnut style
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDayBreakdownPieChart(Map<String, String> t) {
    final cs = Theme.of(context).colorScheme;

    // Same color palette used in Dashboard._buildChartSection
    const List<Color> chartColors = [
      AppColors.error,
      AppColors.accentPurple,
      AppColors.primary,
      AppColors.secondaryLight,
      AppColors.warning,
    ];

    List<PieChartSectionData> pieSections = [];
    List<Widget> legendItems = [];

    for (int i = 0; i < _selectedDayCategoryData.length; i++) {
      final color = chartColors[i % chartColors.length];
      pieSections.add(
        PieChartSectionData(
          color: color,
          value: _selectedDayCategoryData[i].value,
          title: '',
          radius: 20,
        ),
      );
      legendItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildLegendItem(_selectedDayCategoryData[i].key, color),
        ),
      );
    }

    // Fallback empty state
    if (pieSections.isEmpty) {
      pieSections.add(
        PieChartSectionData(
          color: AppColors.greyMedium,
          value: 1,
          title: '',
          radius: 20,
        ),
      );
      legendItems.add(_buildLegendItem(t['no_expenses'] ?? 'No expenses', AppColors.greyMedium));
    }

    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Doughnut chart
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: pieSections,
                    borderData: FlBorderData(show: false),
                  ),
                ),
                // Center label – show the selected day
                Text(
                  _selectedDay ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          // Legend
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: legendItems.isNotEmpty ? legendItems : const [SizedBox()],
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontFamily: 'Inter',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
