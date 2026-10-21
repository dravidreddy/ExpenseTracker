// lib/screens/home_screen.dart
//
// ─── Primary Screen: Quick Entry ─────────────────────────────────────────────
//
// Layout:
//  • Top hero: "Today ₹450" in display-large type
//  • Live category badge updates as user types
//  • Amount field (numeric) + Description field (text)
//  • Animated "+" FAB that morphs and saves the expense

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/categorizer.dart';
import '../core/theme.dart';
import '../data/models/category_meta.dart';
import '../data/models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/category_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _descFocus = FocusNode();

  CategoryMeta? _liveCategory;
  bool _saving = false;
  DateTime _selectedDate = DateTime.now();

  late final AnimationController _fabAnim;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _liveCategory = Categorizer.instance.categorize('');

    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fabScale = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(parent: _fabAnim, curve: Curves.easeInOut),
    );

    _descCtrl.addListener(_onDescChanged);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool get _isYesterday {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return _selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day;
  }

  String get _dateLabel {
    if (_isToday) return 'Today';
    if (_isYesterday) return 'Yesterday';
    return DateFormat('MMM d').format(_selectedDate);
  }

  String get _heroLabel {
    if (_isToday) return 'today';
    if (_isYesterday) return 'yesterday';
    return DateFormat('d MMM').format(_selectedDate).toLowerCase();
  }

  double? _customDateTotal;

  Future<void> _updateDateTotal() async {
    if (_isToday) {
      if (mounted) setState(() => _customDateTotal = null);
    } else {
      final total =
          await context.read<ExpenseProvider>().getTotalForDate(_selectedDate);
      if (mounted) {
        setState(() => _customDateTotal = total);
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
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
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _updateDateTotal();
    }
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    _descCtrl.removeListener(_onDescChanged);
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _amountFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  void _onDescChanged() {
    final cat = Categorizer.instance.categorize(_descCtrl.text);
    if (cat.id != _liveCategory?.id) {
      setState(() => _liveCategory = cat);
    }
  }

  Future<void> _saveExpense() async {
    final amountText = _amountCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (amountText.isEmpty) {
      _amountFocus.requestFocus();
      _shake();
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _shake();
      return;
    }

    setState(() => _saving = true);
    await _fabAnim.forward();

    try {
      final cat = _liveCategory ?? Categorizer.instance.categorize(desc);

      final now = DateTime.now();
      final effectiveDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      final expense = Expense(
        amount: amount,
        description: desc.isEmpty ? cat.label : desc,
        category: cat.id,
        timestamp: effectiveDateTime.millisecondsSinceEpoch,
      );

      if (!mounted) return;
      await context.read<ExpenseProvider>().addExpense(expense);

      _amountCtrl.clear();
      _descCtrl.clear();
      final savedForDate = _selectedDate;
      setState(() {
        _liveCategory = Categorizer.instance.categorize('');
        _selectedDate = DateTime.now();
        _customDateTotal = null;
      });

      _showSavedToast(expense, cat, savedForDate);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        await _fabAnim.reverse();
      }
    }
  }

  void _shake() {
    HapticFeedback.mediumImpact();
  }

  void _showSavedToast(Expense expense, CategoryMeta cat, DateTime savedForDate) {
    final symbol = context.read<SettingsProvider>().symbol;
    final now = DateTime.now();
    final isToday = savedForDate.year == now.year &&
        savedForDate.month == now.month &&
        savedForDate.day == now.day;
    final dateSuffix = isToday ? '' : ' (${DateFormat('MMM d').format(savedForDate)})';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Text(cat.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${expense.description}$dateSuffix  •  $symbol${_fmt(expense.amount)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF34D399), size: 18),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      NumberFormat('#,##0.##').format(v);

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.symbol;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── DATE HERO ───────────────────────────────────────────
                _TodayHero(
                  label: _heroLabel,
                  symbol: symbol,
                  total:
                      _isToday ? expenses.todayTotal : (_customDateTotal ?? 0.0),
                ),

                const SizedBox(height: 56),

                // ── LIVE CATEGORY & DATE SELECTOR ROW ───────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _liveCategory != null
                          ? CategoryBadge(
                              key: ValueKey(_liveCategory!.id),
                              category: _liveCategory!,
                            )
                          : const SizedBox(height: 40),
                    ),
                    _DateChip(
                      label: _dateLabel,
                      isToday: _isToday,
                      onTap: _pickDate,
                      onReset: _isToday
                          ? null
                          : () {
                              setState(() {
                                _selectedDate = DateTime.now();
                                _customDateTotal = null;
                              });
                            },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── AMOUNT FIELD ─────────────────────────────────────────
                _InputField(
                  controller: _amountCtrl,
                  focusNode: _amountFocus,
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  prefixText: '$symbol  ',
                  textStyle: Theme.of(context).textTheme.displayMedium,
                  onSubmitted: (_) => _descFocus.requestFocus(),
                ),

                const SizedBox(height: 16),

                // ── DESCRIPTION FIELD ────────────────────────────────────
                _InputField(
                  controller: _descCtrl,
                  focusNode: _descFocus,
                  hintText: 'What was it for?',
                  textStyle: Theme.of(context).textTheme.titleLarge,
                  onSubmitted: (_) => _saveExpense(),
                ),

                const SizedBox(height: 40),

                // ── SAVE BUTTON ──────────────────────────────────────────
                Center(
                  child: ScaleTransition(
                    scale: _fabScale,
                    child: _SaveButton(
                      saving: _saving,
                      onTap: _saveExpense,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.label,
    required this.symbol,
    required this.total,
  });

  final String label;
  final String symbol;
  final double total;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(label),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  letterSpacing: 2,
                  color: AppTheme.onSurfaceMuted,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              symbol,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 36,
                    color: AppTheme.onSurfaceMuted,
                    fontWeight: FontWeight.w300,
                  ),
            ),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                fmt.format(total),
                key: ValueKey('$label-$total'),
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.prefixText,
    required this.textStyle,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final TextStyle? textStyle;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType ?? TextInputType.text,
      textInputAction: TextInputAction.next,
      inputFormatters: inputFormatters,
      style: textStyle,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        prefixStyle: textStyle?.copyWith(color: AppTheme.onSurfaceMuted),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap, required this.saving});
  final VoidCallback onTap;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: saving ? AppTheme.border : AppTheme.onSurface,
          shape: BoxShape.circle,
          boxShadow: saving
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.onSurface.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.onSurfaceMuted,
                  ),
                )
              : const Icon(
                  Icons.add_rounded,
                  color: AppTheme.background,
                  size: 32,
                ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.isToday,
    required this.onTap,
    this.onReset,
  });

  final String label;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isToday
              ? AppTheme.surfaceVariant
              : const Color(0xFF60A5FA).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isToday
                ? AppTheme.border
                : const Color(0xFF60A5FA).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isToday ? AppTheme.onSurfaceMuted : const Color(0xFF60A5FA),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isToday ? AppTheme.onSurface : const Color(0xFF60A5FA),
                    fontWeight: isToday ? FontWeight.w400 : FontWeight.w600,
                    fontSize: 13,
                  ),
            ),
            if (onReset != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onReset,
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

