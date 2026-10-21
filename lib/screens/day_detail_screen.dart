// lib/screens/day_detail_screen.dart
//
// ─── Daily Detail / Ledger ───────────────────────────────────────────────────
//
// Shows granular expense ledger for a single date.
// "☕ Coffee ..... ₹150"
// Swipe left to delete with confirmation.

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final symbol = context.watch<SettingsProvider>().symbol;
    final expenses = provider.dayExpenses;
    final dateLabel =
        DateFormat('EEEE, MMMM d').format(widget.date);

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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                          Text(
                            '$symbol${NumberFormat('#,##0.##').format(dayTotal)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium,
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
                            final cat = Categorizer.instance
                                .categories
                                .firstWhere(
                                  (c) => c.id == exp.category,
                                  orElse: () => Categorizer.instance
                                      .categorize(exp.description),
                                );
                            return _ExpenseTile(
                              expense: exp,
                              category: cat,
                              symbol: symbol,
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
    required this.onDelete,
  });

  final Expense expense;
  final CategoryMeta category;
  final String symbol;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    final timeLabel =
        DateFormat('h:mm a').format(expense.dateTime);

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
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
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
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
    );
  }
}

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
