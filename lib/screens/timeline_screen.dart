// lib/screens/timeline_screen.dart
//
// ─── Month-by-Month View ──────────────────────────────────────────────────────
//
// Shows: "October 2026 ........ ₹14,500"
// Tap → DateListScreen for that month.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import 'date_list_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().refreshMonthly();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final symbol = context.watch<SettingsProvider>().symbol;
    final months = provider.monthlyTotals;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'timeline',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      letterSpacing: 2,
                      color: AppTheme.onSurfaceMuted,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'All time',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 40),
              if (months.isEmpty)
                _EmptyState()
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: months.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final row = months[i];
                      final year = row['year'] as int;
                      final month = row['month'] as int;
                      final total = (row['total'] as num).toDouble();
                      return _MonthTile(
                        year: year,
                        month: month,
                        total: total,
                        symbol: symbol,
                        onTap: () => Navigator.push(
                          context,
                          _slideRoute(DateListScreen(year: year, month: month)),
                        ),
                      );
                    },
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

class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.year,
    required this.month,
    required this.total,
    required this.symbol,
    required this.onTap,
  });

  final int year, month;
  final double total;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;
    final monthName =
        DateFormat('MMMM').format(DateTime(year, month));
    final fmtTotal = NumberFormat('#,##0.##').format(total);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Month name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          color: isCurrentMonth
                              ? AppTheme.onSurface
                              : AppTheme.onSurface.withValues(alpha: 0.75),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$year',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // Dotted fill
            const _DotFill(),
            // Amount
            Text(
              '$symbol$fmtTotal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
}

class _DotFill extends StatelessWidget {
  const _DotFill();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(
          8,
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏷️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 20),
            Text(
              'No expenses yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first one.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide transition ──────────────────────────────────────────────────────────

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
