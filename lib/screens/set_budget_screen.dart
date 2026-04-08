import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';
import '../services/budget_monitor_service.dart';

class BudgetCategory {
  final TextEditingController name = TextEditingController();
  final TextEditingController amount = TextEditingController();
}

class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({super.key});

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  final TextEditingController totalBudgetCtrl = TextEditingController();
  final List<BudgetCategory> categories = [BudgetCategory()];
  bool _isSaving = false;
  bool _isLoading = true;
  int? _existingBudgetId;

  @override
  void initState() {
    super.initState();
    _loadExistingBudget();
  }

  Future<void> _loadExistingBudget() async {
    try {
      final response = await Supabase.instance.client
          .from('budgets')
          .select()
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(1);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isNotEmpty && mounted) {
        final budget = data.first;
        final List<dynamic> cats = budget['categories_data'] ?? [];

        // Dispose default empty row
        for (var cat in categories) {
          cat.name.dispose();
          cat.amount.dispose();
        }
        categories.clear();

        for (var item in cats) {
          final cat = BudgetCategory();
          cat.name.text = item['name']?.toString() ?? '';
          cat.amount.text = item['amount']?.toString() ?? '';
          categories.add(cat);
        }

        // Ensure at least one row
        if (categories.isEmpty) categories.add(BudgetCategory());

        setState(() {
          _existingBudgetId = budget['id'] as int?;
          totalBudgetCtrl.text = budget['total_budget']?.toString() ?? '';
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    totalBudgetCtrl.dispose();
    for (var cat in categories) {
      cat.name.dispose();
      cat.amount.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (totalBudgetCtrl.text.trim().isEmpty) {
      final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t = AppTranslations.of(lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['enter_total_budget']!, style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final double parsedTotalBudget = double.tryParse(totalBudgetCtrl.text.trim()) ?? 0.0;
    double categoriesSum = 0.0;
    for (var cat in categories) {
      categoriesSum += double.tryParse(cat.amount.text.trim()) ?? 0.0;
    }

    if (categoriesSum > parsedTotalBudget) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Your category allocations (₹$categoriesSum) exceed your total monthly budget (₹$parsedTotalBudget).', style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      List<Map<String, dynamic>> categoriesData = categories
          .where((cat) => cat.name.text.trim().isNotEmpty)
          .map((cat) => {
                'name': cat.name.text.trim(),
                'amount': double.tryParse(cat.amount.text.trim()) ?? 0.0,
              })
          .toList();

      // AI auto-correct category names against historical transaction data
      categoriesData =
          await BudgetMonitorService.autoCorrectCategories(categoriesData);

      if (_existingBudgetId != null) {
        await Supabase.instance.client.from('budgets').update({
          'total_budget': double.parse(totalBudgetCtrl.text.trim()),
          'categories_data': categoriesData,
        }).eq('id', _existingBudgetId!);
      } else {
        await Supabase.instance.client.from('budgets').insert({
          'user_id': Supabase.instance.client.auth.currentUser!.id,
          'total_budget': double.parse(totalBudgetCtrl.text.trim()),
          'categories_data': categoriesData,
        });
      }

      if (!mounted) return;

      final lang3 = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t3 = AppTranslations.of(lang3);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t3['budget_saved']!, style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final lang4 = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t4 = AppTranslations.of(lang4);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t4['failed_save_budget']!}$e', style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: cs.onSurface, size: 30),
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                t['total_monthly_budget']!,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: totalBudgetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 24, right: 4),
                      child: Text(
                        '₹',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['divide_budget']!,
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: Text(
                              t['set_categories']!,
                              style: TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: Text(
                              t['set_amount']!,
                              style: TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), // Space for close icon
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildTextField(
                                  controller: categories[index].name,
                                  hintText: 'e.g., Groceries',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: _buildTextField(
                                  controller: categories[index].amount,
                                  hintText: 'e.g., 500',
                                  isNumber: true,
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: IconButton(
                                  onPressed: categories.length > 1
                                      ? () {
                                          setState(() {
                                            categories[index].name.dispose();
                                            categories[index].amount.dispose();
                                            categories.removeAt(index);
                                          });
                                        }
                                      : null,
                                  icon: Icon(Icons.close, color: cs.onSurface, size: 28),
                                  splashRadius: 24,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          categories.add(BudgetCategory());
                        });
                      },
                      icon: const Icon(Icons.add, color: AppColors.white),
                      label: Text(
                        t['add_categories']!,
                        style: const TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBudget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                              )
                            : Text(
                                t['save_budget']!,
                                style: const TextStyle(
                                  fontFamily: 'SF Pro',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))] : null,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'SF Pro',
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: AppColors.textHint,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      style: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
