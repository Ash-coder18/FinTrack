import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  // ── Realtime Stream ────────────────────────────────────────
  late final Stream<List<Map<String, dynamic>>> _transactionsStream;

  // ── Filter State ───────────────────────────────────────────
  String _selectedType = 'All';
  String _selectedTime = 'All Time';

  // ── Selection Mode State ───────────────────────────────────
  bool _isSelectionMode = false;
  final Set<dynamic> _selectedTransactionIds = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _transactionsStream = Supabase.instance.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id);
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactionIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Container(
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
                // ── Header ─────────────────────────────────────
                _isSelectionMode
                    ? _buildSelectionHeader(t)
                    : _buildNormalHeader(t),
                const SizedBox(height: 32),

                // ── StreamBuilder (auto-updates) ─────────────
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _transactionsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('${t['error_prefix']!}${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(t);
                    }

                    // Sort by created_at descending (stream doesn't support .order())
                    final sorted = List<Map<String, dynamic>>.from(snapshot.data!);
                    sorted.sort((a, b) {
                      final aDate = a['created_at'] ?? '';
                      final bDate = b['created_at'] ?? '';
                      return bDate.compareTo(aDate);
                    });

                    // Apply filters before building
                    final transactions = _applyFilters(sorted);
                    if (transactions.isEmpty) {
                      return _buildEmptyFilterState(t);
                    }
                    return _buildTransactionList(transactions);
                  },
                ),
              ],
            ),
          ),
        ),

        // ── Loading overlay during deletion ────────────────────
        if (_isDeleting)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.white),
            ),
          ),
      ],
    );
  }

  // ── Normal Header (Filter + Delete icons) ─────────────────────
  Widget _buildNormalHeader(Map<String, String> t) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t['transaction_details']!,
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showFilterSheet(t),
              child: Icon(Icons.filter_alt_outlined,
                  color: cs.onSurface, size: 24),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() => _isSelectionMode = true);
              },
              child: Icon(Icons.delete_outline_rounded,
                  color: cs.onSurface, size: 24),
            ),
          ],
        ),
      ],
    );
  }

  // ── Selection Mode Header ─────────────────────────────────────
  Widget _buildSelectionHeader(Map<String, String> t) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_selectedTransactionIds.length} ${t['selected']!}',
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _exitSelectionMode,
              child: Icon(Icons.close_rounded,
                  color: cs.onSurface, size: 24),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _selectedTransactionIds.isEmpty
                  ? null
                  : _confirmAndDelete,
              child: Icon(
                Icons.delete_forever_rounded,
                color: _selectedTransactionIds.isEmpty
                    ? AppColors.greyMedium
                    : AppColors.error,
                size: 26,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Confirm & Delete ──────────────────────────────────────────
  Future<void> _confirmAndDelete() async {
    final count = _selectedTransactionIds.length;
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
    final t = AppTranslations.of(lang);

    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t['delete_transactions_title']!,
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          '${t['delete_transactions_msg_1']!}$count${t['delete_transactions_msg_2']!}${count > 1 ? 's' : ''}${t['delete_transactions_msg_3']!}',
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t['cancel']!,
              style: const TextStyle(
                fontFamily: 'SF Pro',
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t['delete']!,
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

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await Supabase.instance.client
          .from('transactions')
          .delete()
          .inFilter('id', _selectedTransactionIds.toList());

      // Exit selection mode — stream auto-refreshes the list
      setState(() {
        _isSelectionMode = false;
        _selectedTransactionIds.clear();
        _isDeleting = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$count ${t['txn_deleted']!}${count > 1 ? 's' : ''}${t['txn_deleted_suffix']!}',
            style: const TextStyle(
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      setState(() => _isDeleting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${t['delete_failed']!}$e',
            style: const TextStyle(fontFamily: 'SF Pro'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Filter Logic ─────────────────────────────────────────────
  List<dynamic> _applyFilters(List<dynamic> all) {
    return all.where((tx) {
      // Type filter
      if (_selectedType != 'All' && tx['type'] != _selectedType) {
        return false;
      }

      // Time filter
      if (_selectedTime != 'All Time') {
        final createdAt = DateTime.tryParse(tx['created_at'] ?? '');
        if (createdAt == null) return false;

        final now = DateTime.now();
        if (_selectedTime == 'Last 7 Days') {
          if (createdAt.isBefore(now.subtract(const Duration(days: 7)))) {
            return false;
          }
        } else if (_selectedTime == 'This Month') {
          if (createdAt.month != now.month || createdAt.year != now.year) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  // ── Filter Bottom Sheet ──────────────────────────────────────
  void _showFilterSheet(Map<String, String> t) {
    String tempType = _selectedType;
    String tempTime = _selectedTime;

    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle bar ────────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t['filter_transactions']!,
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Type Filter ───────────────────────────
                  Text(
                    t['type']!,
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      {'key': 'All', 'label': t['all']!},
                      {'key': 'Income', 'label': t['income']!},
                      {'key': 'Expense', 'label': t['expense']!},
                    ].map((item) {
                      final isSelected = tempType == item['key'];
                      return ChoiceChip(
                        label: Text(
                          item['label']!,
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected ? AppColors.white : cs.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: cs.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : cs.outlineVariant,
                          ),
                        ),
                        onSelected: (_) {
                          setSheetState(() => tempType = item['key']!);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Time Filter ───────────────────────────
                  Text(
                    t['time']!,
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      {'key': 'All Time', 'label': t['all_time']!},
                      {'key': 'Last 7 Days', 'label': t['last_7_days']!},
                      {'key': 'This Month', 'label': t['this_month']!},
                    ].map((item) {
                      final isSelected = tempTime == item['key'];
                      return ChoiceChip(
                        label: Text(
                          item['label']!,
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected ? AppColors.white : cs.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: cs.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : cs.outlineVariant,
                          ),
                        ),
                        onSelected: (_) {
                          setSheetState(() => tempTime = item['key']!);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ── Apply Button ──────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = tempType;
                          _selectedTime = tempTime;
                        });
                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        t['apply_filters']!,
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
            );
          },
        );
      },
    );
  }

  // ── Empty State (preserved from original design) ─────────────
  Widget _buildEmptyState(Map<String, String> t) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 80,
              color: AppColors.greyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              t['no_txn_yet']!,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t['no_txn_hint']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state after filtering ──────────────────────────────
  Widget _buildEmptyFilterState(Map<String, String> t) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.filter_alt_off_rounded,
              size: 60,
              color: AppColors.greyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              t['no_matching_txn']!,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t['try_adjust_filters']!,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction List ─────────────────────────────────────────
  Widget _buildTransactionList(List<dynamic> transactions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) =>
          Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 24),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final txId = tx['id'];
        final isIncome = tx['type'] == 'Income';
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        final category =
            tx['category'] as String? ?? (isIncome ? 'Income' : '—');
        final method =
            tx['method'] as String? ?? (isIncome ? 'Direct' : '—');
        final notes = tx['notes'] as String? ?? '';

        final createdAtStr = tx['created_at'] as String?;
        String dateStr = '';
        if (createdAtStr != null) {
          final parsedDate = DateTime.tryParse(createdAtStr);
          if (parsedDate != null) {
            dateStr = DateFormat('MMM dd').format(parsedDate);
          }
        }

        // Format amount with sign and symbol
        final amountText = isIncome
            ? '+₹ ${amount.toStringAsFixed(2)}'
            : '-₹ ${amount.toStringAsFixed(2)}';

        return _buildTransactionTile(
          txId: txId,
          category: category,
          method: method,
          notes: notes,
          dateString: dateStr,
          amountText: amountText,
          isIncome: isIncome,
        );
      },
    );
  }

  // ── Single Transaction Tile ──────────────────────────────────
  Widget _buildTransactionTile({
    required dynamic txId,
    required String category,
    required String method,
    required String notes,
    required String dateString,
    required String amountText,
    required bool isIncome,
  }) {
    final isChecked = _selectedTransactionIds.contains(txId);

    return GestureDetector(
      onTap: _isSelectionMode
          ? () {
              setState(() {
                if (isChecked) {
                  _selectedTransactionIds.remove(txId);
                } else {
                  _selectedTransactionIds.add(txId);
                }
              });
            }
          : null,
      child: Row(
        children: [
          // ── Checkbox (only in selection mode) ──────────
          if (_isSelectionMode) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isChecked,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedTransactionIds.add(txId);
                      } else {
                        _selectedTransactionIds.remove(txId);
                      }
                    });
                  },
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isIncome ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Category + method / notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (dateString.isNotEmpty) dateString,
                    method,
                    if (notes.isNotEmpty) notes
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            amountText,
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isIncome ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
