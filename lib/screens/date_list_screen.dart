// lib/screens/date_list_screen.dart
//
// ─── Date Drill-Down ──────────────────────────────────────────────────────────
//
// Shows all dates with activity in the selected month.
// "Oct 6, Tuesday ........ ₹450"
// Tap → DayDetailScreen.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import 'day_detail_screen.dart';

class DateListScreen extends StatefulWidget {
  const DateListScreen({super.key, required this.year, required this.month});
  final int year;
  final int month;

  @override
  State<DateListScreen> createState() => _DateListScreenState();
}

class _DateListScreenState extends State<DateListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ExpenseProvider>()
          .loadDailyTotals(widget.year, widget.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final symbol = context.watch<SettingsProvider>().symbol;
    final days = provider.dailyTotals;
    final monthLabel =
        DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: const _BackButton(),
        title: Text(monthLabel),
      ),
      body: provider.loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.onSurfaceMuted,
                strokeWidth: 1.5,
              ),
            )
          : days.isEmpty
              ? Center(
                  child: Text(
                    'Nothing logged this month.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final row = days[i];
                    final day = row['day'] as int;
                    final total = (row['total'] as num).toDouble();
                    final date = DateTime(widget.year, widget.month, day);

                    return _DateTile(
                      date: date,
                      total: total,
                      symbol: symbol,
                      onTap: () => Navigator.push(
                        context,
                        _slideRoute(DayDetailScreen(date: date)),
                      ),
                    );
                  },
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.date,
    required this.total,
    required this.symbol,
    required this.onTap,
  });

  final DateTime date;
  final double total;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('MMM d').format(date);
    final weekday = DateFormat('EEEE').format(date);
    final fmtTotal = NumberFormat('#,##0.##').format(total);
    final isToday = _isToday(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dayLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: isToday
                                  ? AppTheme.onSurface
                                  : AppTheme.onSurface.withValues(alpha: 0.8),
                            ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'today',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weekday,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            _DotFill(),
            Text(
              '$symbol$fmtTotal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppTheme.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _DotFill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: AppTheme.border,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      onPressed: () => Navigator.pop(context),
    );
  }
}

Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, anim, __, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: slide, child: child);
    },
  );
}
