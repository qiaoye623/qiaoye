import 'package:flutter/foundation.dart';
import '../models/ledger.dart';
import '../database/database_helper.dart';

class LedgerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Ledger> _ledgers = [];
  Ledger? _currentLedger;
  bool _loading = false;
  Map<int, Map<String, double>> _ledgerSummaries = {};

  List<Ledger> get ledgers => _ledgers;
  Ledger? get currentLedger => _currentLedger;
  bool get loading => _loading;

  double getLedgerIncome(int id) => _ledgerSummaries[id]?['income'] ?? 0;
  double getLedgerExpense(int id) => _ledgerSummaries[id]?['expense'] ?? 0;
  double getLedgerBalance(int id) =>
      (_ledgerSummaries[id]?['income'] ?? 0) - (_ledgerSummaries[id]?['expense'] ?? 0);

  Future<void> loadLedgers() async {
    _loading = true;
    notifyListeners();

    _ledgers = await _db.getLedgers();
    await _loadAllSummaries();
    if (_currentLedger == null) {
      _currentLedger = _ledgers.isNotEmpty ? _ledgers.first : null;
    } else {
      final stillExists = _ledgers.any((l) => l.id == _currentLedger!.id);
      if (!stillExists) {
        _currentLedger = _ledgers.isNotEmpty ? _ledgers.first : null;
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadAllSummaries() async {
    _ledgerSummaries = {};
    for (final l in _ledgers) {
      if (l.id != null) {
        _ledgerSummaries[l.id!] = await _db.getLedgerSummary(l.id!);
      }
    }
  }

  Future<void> switchLedger(int id) async {
    final found = _ledgers.where((l) => l.id == id);
    if (found.isNotEmpty) {
      _currentLedger = found.first;
      notifyListeners();
    }
  }

  Future<Ledger> createLedger(String name, String icon) async {
    if (_ledgers.length >= 20) {
      throw Exception('最多创建20个账本');
    }
    final ledger = Ledger(
      name: name,
      icon: icon,
      sortOrder: _ledgers.length,
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await _db.insertLedger(ledger);
    final created = ledger.copyWith(id: id);
    _ledgers.add(created);
    _ledgerSummaries[id] = {'income': 0, 'expense': 0};
    notifyListeners();
    return created;
  }

  Future<void> updateLedger(int id, String name, String icon) async {
    final updated = _ledgers.firstWhere((l) => l.id == id);
    final newLedger = updated.copyWith(name: name, icon: icon);
    await _db.updateLedger(newLedger);
    final index = _ledgers.indexWhere((l) => l.id == id);
    if (index != -1) {
      _ledgers[index] = newLedger;
    }
    if (_currentLedger?.id == id) {
      _currentLedger = newLedger;
    }
    notifyListeners();
  }

  Future<void> deleteLedger(int id) async {
    if (_ledgers.length <= 1) {
      throw Exception('至少保留一个账本');
    }
    await _db.deleteLedger(id);
    _ledgers.removeWhere((l) => l.id == id);
    _ledgerSummaries.remove(id);
    if (_currentLedger?.id == id) {
      _currentLedger = _ledgers.isNotEmpty ? _ledgers.first : null;
    }
    notifyListeners();
  }
}
