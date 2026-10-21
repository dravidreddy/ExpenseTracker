// lib/screens/day_detail_screen.dart
//
// ─── Daily Detail / Ledger ───────────────────────────────────────────────────
//
// Shows granular expense ledger for a single date.
// "☕ Coffee ..... ₹150"
// Swipe left or tap to edit; swipe left to delete with confirmation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/categorizer.dart';
import '../core/theme.dart';
import '../data/models/category_meta.dart';
import '../data/models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';

class DayDetailScreen extends StatefulWidget {
  const DayDetailScreen({super.key, required this.date});
  final DateTime date;

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadDayExpenses(widget.date);
    });
  }

  Future<void> _delete(Expense expense) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteDialog(expense: expense),
    );
    if (confirmed == true && mounted) {
      await context
          .read<ExpenseProvider>()
          .deleteExpense(expense.id!, widget.date);
    }
  }

  Future<void> _edit(Expense expense) async {
    HapticFeedback.lightImpact();
    final updated = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditExpenseSheet(
        expense: expense,
        date: widget.date,
      ),
    );

    if (updated != null && mounted) {
      await context
          .read<ExpenseProvider>()
          .updateExpense(updated, widget.date);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final symbol = context.watch<SettingsProvider>().symbol;
    final expenses = provider.dayExpenses;
    final dateLabel = DateFormat('EEEE, MMMM d').format(widget.date);

    final dayTotal = expenses.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(dateLabel),
      ),
      body: provider.loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.onSurfaceMuted,
                strokeWidth: 1.5,
              ),
            )
          : expenses.isEmpty
              ? Center(
                  child: Text(
                    'Nothing logged today.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day total banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${expenses.length} item${expenses.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '$symbol${NumberFormat('#,##0.##').format(dayTotal)}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: SlidableAutoCloseBehavior(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: expenses.length,
                          separatorBuilder: (_, __) =>
                              const Divider(indent: 28, endIndent: 28),
                          itemBuilder: (context, i) {
                            final exp = expenses[i];
                            final cat = Categorizer.instance.categories.firstWhere(
                              (c) => c.id == exp.category,
                              orElse: () => Categorizer.instance.categorize(exp.description),
                            );
                            return _ExpenseTile(
                              expense: exp,
                              category: cat,
                              symbol: symbol,
                              onEdit: () => _edit(exp),
                              onDelete: () => _delete(exp),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.symbol,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final CategoryMeta category;
  final String symbol;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    final timeLabel = DateFormat('h:mm a').format(expense.dateTime);

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.44,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: const Icon(Icons.edit_outlined, size: 22),
          ),
          CustomSlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
            child: const Icon(Icons.delete_outline_rounded, size: 22),
          ),
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category emoji badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Description + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          timeLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• Tap to edit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                color: AppTheme.onSurfaceMuted.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '$symbol${fmt.format(expense.amount)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Expense Modal Sheet (Double-Bezel Agency Grade)
// ─────────────────────────────────────────────────────────────────────────────

class _EditExpenseSheet extends StatefulWidget {
  const _EditExpenseSheet({
    required this.expense,
    required this.date,
  });

  final Expense expense;
  final DateTime date;

  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedCategoryId;
  late DateTime _selectedTimestamp;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(
        widget.expense.amount.truncateToDouble() == widget.expense.amount ? 0 : 2,
      ),
    );
    _descCtrl = TextEditingController(text: widget.expense.description);
    _selectedCategoryId = widget.expense.category;
    _selectedTimestamp = widget.expense.dateTime;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amountText = _amountCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final updated = widget.expense.copyWith(
      amount: amount,
      description: desc.isEmpty ? 'Expense' : desc,
      category: _selectedCategoryId,
      timestamp: _selectedTimestamp.millisecondsSinceEpoch,
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.read<SettingsProvider>().symbol;
    final categories = Categorizer.instance.categories;

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: viewInsets),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Expense',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppTheme.onSurfaceMuted,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Text(
                      '$symbol ',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Description Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _descCtrl,
                  style: Theme.of(context).textTheme.titleMedium,
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Picker Section
              Text(
                'Category',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                      fontSize: 13,
                    ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = cat.id == _selectedCategoryId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategoryId = cat.id);
                            HapticFeedback.selectionClick();
                          }
                        },
                        avatar: Text(cat.emoji),
                        label: Text(cat.label),
                        selectedColor: cat.color.withValues(alpha: 0.25),
                        backgroundColor: AppTheme.surfaceVariant,
                        side: BorderSide(
                          color: isSelected ? cat.color : AppTheme.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // Save Changes Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.onSurface,
                    foregroundColor: AppTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppTheme.background,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete expense?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              '"${expense.description}" will be permanently removed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
