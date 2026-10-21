// lib/providers/expense_provider.dart
import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models/expense.dart';

/// Manages expense state and bridges the UI with SQLite.
class ExpenseProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  // ── Today state ───────────────────────────────────────────────────────────
  double _todayTotal = 0;
  double get todayTotal => _todayTotal;

  // ── Timeline state ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _monthlyTotals = [];
  List<Map<String, dynamic>> get monthlyTotals =>
      List.unmodifiable(_monthlyTotals);

  // ── Daily state (for date-drill-down) ────────────────────────────────────
  List<Map<String, dynamic>> _dailyTotals = [];
  List<Map<String, dynamic>> get dailyTotals =>
      List.unmodifiable(_dailyTotals);

  // ── Day detail state ──────────────────────────────────────────────────────
  List<Expense> _dayExpenses = [];
  List<Expense> get dayExpenses => List.unmodifiable(_dayExpenses);

  bool _loading = false;
  bool get loading => _loading;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await refreshToday();
    await refreshMonthly();
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> addExpense(Expense expense) async {
    await _db.insertExpense(expense);
    await refreshToday();
    await refreshMonthly();
  }

  Future<void> deleteExpense(int id, DateTime forDate) async {
    await _db.deleteExpense(id);
    await refreshToday();
    await refreshMonthly();
    await loadDayExpenses(forDate);
    await loadDailyTotals(forDate.year, forDate.month);
  }

  Future<void> updateExpense(Expense expense, DateTime forDate) async {
    await _db.updateExpense(expense);
    await refreshToday();
    await refreshMonthly();
    await loadDayExpenses(forDate);
    await loadDailyTotals(forDate.year, forDate.month);
  }

  Future<void> clearAllData() async {
    await _db.clearAllData();
    _todayTotal = 0;
    _monthlyTotals = [];
    _dailyTotals = [];
    _dayExpenses = [];
    notifyListeners();
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<double> getTotalForDate(DateTime date) => _db.getTotalForDate(date);

  Future<void> refreshToday() async {
    _todayTotal = await _db.getTodayTotal();
    notifyListeners();
  }

  Future<void> refreshMonthly() async {
    _monthlyTotals = await _db.getMonthlyTotals();
    notifyListeners();
  }

  Future<void> loadDailyTotals(int year, int month) async {
    _loading = true;
    notifyListeners();
    _dailyTotals = await _db.getDailyTotalsForMonth(year, month);
    _loading = false;
    notifyListeners();
  }

  Future<void> loadDayExpenses(DateTime date) async {
    _loading = true;
    notifyListeners();
    _dayExpenses = await _db.getExpensesForDate(date);
    _loading = false;
    notifyListeners();
  }
}
