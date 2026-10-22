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
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.date;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadDayExpenses(_currentDate);
    });
  }

  void _shiftDate(int deltaDays) {
    HapticFeedback.selectionClick();
    final newDate = _currentDate.add(Duration(days: deltaDays));
    setState(() => _currentDate = newDate);
    context.read<ExpenseProvider>().loadDayExpenses(newDate);
  }

  bool _isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isAfter(today);
  }

  Future<void> _pickTimelineDate() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate.isAfter(now) ? now : _currentDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            onPrimary: AppTheme.background,
            surface: AppTheme.surfaceVariant,
            onSurface: AppTheme.onSurface,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppTheme.surfaceVariant,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _currentDate = picked);
      await context.read<ExpenseProvider>().loadDayExpenses(picked);
    }
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
          .deleteExpense(expense.id!, _currentDate);
    }
  }

  Future<void> _edit(Expense expense) async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<_EditExpenseResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditExpenseSheet(
        expense: expense,
      ),
    );

    if (result != null && mounted) {
      if (result.isDelete) {
        if (!mounted) return;
        await context
            .read<ExpenseProvider>()
            .deleteExpense(expense.id!, _currentDate);
        HapticFeedback.mediumImpact();
      } else if (result.updatedExpense != null) {
        if (!mounted) return;
        await context
            .read<ExpenseProvider>()
            .updateExpense(result.updatedExpense!, _currentDate);
        if (!mounted) return;
        await context.read<ExpenseProvider>().loadDayExpenses(_currentDate);
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final symbol = context.watch<SettingsProvider>().symbol;
    final expenses = provider.dayExpenses;
    final dateLabel = DateFormat('EEEE, MMMM d').format(_currentDate);

    final dayTotal = expenses.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: _pickTimelineDate,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    dateLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppTheme.onSurfaceMuted,
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            tooltip: 'Previous day',
            onPressed: () => _shiftDate(-1),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 19),
            tooltip: 'Select date',
            onPressed: _pickTimelineDate,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            tooltip: 'Next day',
            onPressed: _isFutureDate(_currentDate.add(const Duration(days: 1)))
                ? null
                : () => _shiftDate(1),
          ),
          const SizedBox(width: 4),
        ],
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

class _EditExpenseResult {
  final bool isDelete;
  final Expense? updatedExpense;

  _EditExpenseResult.update(this.updatedExpense) : isDelete = false;
  _EditExpenseResult.delete() : isDelete = true, updatedExpense = null;
}

class _EditExpenseSheet extends StatefulWidget {
  const _EditExpenseSheet({
    required this.expense,
  });

  final Expense expense;

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

  Future<void> _pickDateOnly() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedTimestamp.isAfter(now) ? now : _selectedTimestamp,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            onPrimary: AppTheme.background,
            surface: AppTheme.surfaceVariant,
            onSurface: AppTheme.onSurface,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppTheme.surfaceVariant,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedTimestamp = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedTimestamp.hour,
        _selectedTimestamp.minute,
      );
    });
  }

  Future<void> _pickTimeOnly() async {
    HapticFeedback.lightImpact();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTimestamp),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            onPrimary: AppTheme.background,
            surface: AppTheme.surfaceVariant,
            onSurface: AppTheme.onSurface,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppTheme.surfaceVariant,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedTimestamp = DateTime(
        _selectedTimestamp.year,
        _selectedTimestamp.month,
        _selectedTimestamp.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _delete() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteDialog(expense: widget.expense),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, _EditExpenseResult.delete());
    }
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

    Navigator.pop(context, _EditExpenseResult.update(updated));
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
          child: SingleChildScrollView(
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
                const SizedBox(height: 14),

                // Date & Optional Time Selectors
                Row(
                  children: [
                    // Date Selector
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: _pickDateOnly,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 15,
                                  color: AppTheme.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.onSurfaceMuted.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('EEE, MMM d, yyyy').format(_selectedTimestamp),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Optional Time Selector
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _pickTimeOnly,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  size: 15,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time (Opt)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.onSurfaceMuted.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('h:mm a').format(_selectedTimestamp),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                const SizedBox(height: 12),

                // Direct Delete Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'Delete Expense',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x33EF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
