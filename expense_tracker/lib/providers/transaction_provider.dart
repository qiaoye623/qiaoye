import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../database/database_helper.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Transaction> _transactions = [];
  List<models.Category> _expenseCategories = [];
  List<models.Category> _incomeCategories = [];
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;
  bool _loading = false;
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;
  int? _currentLedgerId;

  List<Transaction> get transactions => _transactions;
  List<models.Category> get expenseCategories => _expenseCategories;
  List<models.Category> get incomeCategories => _incomeCategories;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpense => _monthlyExpense;
  double get balance => _monthlyIncome - _monthlyExpense;
  bool get loading => _loading;
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;
  int? get currentLedgerId => _currentLedgerId;

  void setCurrentLedgerId(int? id) {
    if (_currentLedgerId == id) return;
    _currentLedgerId = id;
    loadMonthlyTransactions();
  }

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    try {
      final expCats = _db.getCategories('expense');
      final incCats = _db.getCategories('income');
      final results = await Future.wait([expCats, incCats]);
      _expenseCategories = results[0];
      _incomeCategories = results[1];
      await loadMonthlyTransactions();
    } catch (e) {
      debugPrint('Failed to load transaction data: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadMonthlyTransactions() async {
    _transactions = await _db.getTransactionsByMonth(
      _currentYear,
      _currentMonth,
      ledgerId: _currentLedgerId,
    );
    _monthlyIncome = 0;
    _monthlyExpense = 0;
    for (final t in _transactions) {
      if (t.type == 'income') {
        _monthlyIncome += t.amount;
      } else {
        _monthlyExpense += t.amount;
      }
    }
    notifyListeners();
  }

  void goToMonth(int year, int month) {
    _currentYear = year;
    _currentMonth = month;
    loadMonthlyTransactions();
  }

  void goToPrevMonth() {
    final newMonth = _currentMonth - 1;
    _currentYear = newMonth == 0 ? _currentYear - 1 : _currentYear;
    _currentMonth = newMonth == 0 ? 12 : newMonth;
    loadMonthlyTransactions();
  }

  void goToNextMonth() {
    final newMonth = _currentMonth + 1;
    _currentYear = newMonth == 13 ? _currentYear + 1 : _currentYear;
    _currentMonth = newMonth == 13 ? 1 : newMonth;
    loadMonthlyTransactions();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _db.insertTransaction(transaction);
    await loadMonthlyTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await loadMonthlyTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _db.updateTransaction(transaction);
    await loadMonthlyTransactions();
  }

  Future<Map<String, double>> getCategorySummary(String type) async {
    return await _db.getCategorySummary(
      _currentYear,
      _currentMonth,
      type,
      ledgerId: _currentLedgerId,
    );
  }

  Future<Map<String, double>> getDailySummariesForMonth() async {
    return await _db.getDailySummariesForMonth(
      _currentYear,
      _currentMonth,
      ledgerId: _currentLedgerId,
    );
  }
}
