import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';
import '../services/budget_monitor_service.dart';
import '../widgets/theme_aware_logo.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isExpense = true;
  bool _isLoading = false;
  String? _selectedMethod;
  String? _selectedCategory;
  File? _selectedImage;

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _customCategoryController = TextEditingController();

  final List<String> _methods = ['UPI', 'CASH', 'Card', 'Net Banking'];
  final List<String> _categories = ['Food', 'Shopping', 'OTT', 'Travels', 'Others'];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  // Uniform input decoration for ALL fields
  static const _contentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const _fieldRadius = 16.0;

  InputDecoration _fieldDecoration({String hint = '', Widget? suffix}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textHint,
        fontFamily: 'SF Pro',
        fontSize: 14,
      ),
      contentPadding: _contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Transaction',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.white, size: 32),
                  ),
                ],
              ),
            ),

            // White form area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _buildToggle(t)),
                      const SizedBox(height: 32),
                      if (_isExpense) _buildExpenseForm(t) else _buildIncomeForm(t),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───── Toggle Switch ─────
  Widget _buildToggle(Map<String, String> t) {
    return Container(
      width: 240,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _isExpense ? 0 : 120,
            child: Container(
              width: 120,
              height: 50,
              decoration: BoxDecoration(
                color: _isExpense ? AppColors.error : AppColors.success,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isExpense = true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      t['expense_label']!,
                      style: const TextStyle(
                        color: AppColors.white,
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
                  onTap: () => setState(() => _isExpense = false),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      t['income_label']!,
                      style: const TextStyle(
                        color: AppColors.white,
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

  // ───── Expense Form ─────
  Widget _buildExpenseForm(Map<String, String> t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(t['transaction_method']!),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedMethod,
          items: _methods,
          onChanged: (v) => setState(() => _selectedMethod = v),
        ),
        const SizedBox(height: 16),

        _buildLabel(t['amount']!),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          decoration: _fieldDecoration(),
        ),
        const SizedBox(height: 16),

        _buildLabel(t['category']!),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedCategory,
          items: _categories,
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),

        // Conditional "Others" custom category field
        if (_selectedCategory == 'Others') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _customCategoryController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
            decoration: _fieldDecoration(hint: t['enter_custom_category']!),
          ),
        ],

        const SizedBox(height: 16),
        _buildLabel(t['notes']!),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          decoration: _fieldDecoration(),
        ),
        const SizedBox(height: 24),

        Center(
          child: Text(
            'OR',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabel(t['ai_auto_scan']!),
        const SizedBox(height: 8),
        _buildAiScanButton(),
        const SizedBox(height: 32),

        Center(child: _buildSubmitButton(t)),
        const SizedBox(height: 24),
      ],
    );
  }

  // ───── Income Form ─────
  Widget _buildIncomeForm(Map<String, String> t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(t['amount']!),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          decoration: _fieldDecoration(),
        ),
        const SizedBox(height: 16),

        _buildLabel(t['notes']!),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          decoration: _fieldDecoration(),
        ),

        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        Center(child: _buildSubmitButton(t)),
        const SizedBox(height: 24),
      ],
    );
  }

  // ───── Shared Widgets ─────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
        fontFamily: 'SF Pro',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      hint: const Text(''),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
      dropdownColor: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      decoration: _fieldDecoration(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
        fontFamily: 'SF Pro',
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _selectedImage = file;
      });
      _analyzeReceipt(file);
    }
  }

  Future<void> _analyzeReceipt(File imageFile) async {
    if (!mounted) return;
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
    final t = AppTranslations.of(lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t['ai_scanning']!, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: 'AIzaSyCpzTR8votJY0ug5SZ-1mXyqJcspguo6Hg'
      );

      final prompt = "Analyze this receipt or transaction screenshot. Extract the total amount. Categorize it STRICTLY into one of these exact strings: 'Food', 'Shopping', 'OTT', 'Travels', 'Others'. Create a short 2-3 word note describing the purchase. If the transaction method isn't clear from the receipt, default the \"method\" to \"CASH\". Otherwise select from ['UPI', 'CASH', 'Card', 'Net Banking']. Return the result EXACTLY as a raw JSON object with no markdown formatting, like this: {\"amount\": \"150.00\", \"category\": \"Food\", \"notes\": \"Zomato delivery\", \"method\": \"UPI\"}.";

      final imageBytes = await imageFile.readAsBytes();
      
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      if (!mounted) return;

      final textResponse = response.text?.trim() ?? '';
      
      // Clean up markdown block wrapping if model injects it
      String cleanText = textResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = jsonDecode(cleanText);

      setState(() {
        if (data.containsKey('amount')) {
          _amountController.text = data['amount'].toString();
        }
        if (data.containsKey('category')) {
          final returnedCategory = data['category'].toString();
          if (_categories.contains(returnedCategory)) {
            _selectedCategory = returnedCategory;
          } else {
            _selectedCategory = 'Others';
            _customCategoryController.text = returnedCategory;
          }
        }
        if (data.containsKey('notes')) {
          _notesController.text = data['notes'].toString();
        }
        if (data.containsKey('method')) {
          final returnedMethod = data['method'].toString();
          if (_methods.contains(returnedMethod)) {
            _selectedMethod = returnedMethod;
          } else {
            _selectedMethod = 'CASH';
          }
        }
      });
      
      final lang2 = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t2 = AppTranslations.of(lang2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t2['auto_fill_complete']!, style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

    } catch (e) {
      debugPrint('AI Scan Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Scan Failed: $e', style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showImageSourceDialog() {
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
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppTranslations.of(Provider.of<SettingsProvider>(context, listen: false).languageLabel)['take_photo']!, style: const TextStyle(fontFamily: 'Inter')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppTranslations.of(Provider.of<SettingsProvider>(context, listen: false).languageLabel)['choose_from_gallery']!, style: const TextStyle(fontFamily: 'Inter')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiScanButton() {
    if (_selectedImage != null) {
      return Stack(
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImage = null),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            Icons.document_scanner_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(Map<String, String> t) {
    return SizedBox(
      width: 200,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
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
                AppTranslations.of(Provider.of<SettingsProvider>(context, listen: false).languageLabel)['submit']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'SF Pro',
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _submitTransaction() async {
    // ── Validate ──────────────────────────────────────────────
    if (_amountController.text.trim().isEmpty) {
      final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t = AppTranslations.of(lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['enter_amount']!,
              style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_isExpense && _selectedMethod == null) {
      final lang3 = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t3 = AppTranslations.of(lang3);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t3['select_method']!,
              style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Resolve category — use custom text if "Others" is selected
      String finalCategory = _selectedCategory == 'Others'
          ? _customCategoryController.text.trim()
          : (_selectedCategory ?? 'Others');
      
      if (finalCategory.isEmpty) {
        finalCategory = 'Others';
      }

      await Supabase.instance.client.from('transactions').insert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'type': _isExpense ? 'Expense' : 'Income',
        'method': _isExpense ? _selectedMethod : null,
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'category': _isExpense ? finalCategory : null,
        'notes': _notesController.text.trim(),
      });

      if (!mounted) return;

      // AI Budget Overrun Check — only for expenses
      if (_isExpense) {
        await BudgetMonitorService.checkBudgetOverrun();
        // Re-schedule the daily summary with updated totals
        await BudgetMonitorService.scheduleExactDailySummary();
      }

      if (!mounted) return;
      final lang4 = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t4 = AppTranslations.of(lang4);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t4['txn_saved']!,
              style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
