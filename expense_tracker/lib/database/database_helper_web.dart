import 'package:sembast_web/sembast_web.dart' hide Transaction;
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/ledger.dart';
import '../models/asset_account.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final db = await databaseFactoryWeb.openDatabase('expense_tracker.db');
    await _ensureDefaults(db);
    return db;
  }

  Future<void> _ensureDefaults(Database db) async {
    final catStore = _categoryStore();
    if (await catStore.count(db) == 0) {
      for (final cat in DefaultCategories.expense) {
        await catStore.add(db, {
          'name': cat['name'],
          'icon': cat['icon'],
          'type': 'expense',
        });
      }
      for (final cat in DefaultCategories.income) {
        await catStore.add(db, {
          'name': cat['name'],
          'icon': cat['icon'],
          'type': 'income',
        });
      }
    }

    final ledgerStore = _ledgerStore();
    if (await ledgerStore.count(db) == 0) {
      await ledgerStore.add(db, {
        'name': '个人账本',
        'icon': '📒',
        'isDefault': 1,
        'sortOrder': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    final assetStore = _assetAccountStore();
    if (await assetStore.count(db) == 0) {
      final defaults = [
        {'name': '微信', 'icon': '💳', 'type': 'wallet', 'balance': 0.0, 'isDefault': 1},
        {'name': '支付宝', 'icon': '📱', 'type': 'wallet', 'balance': 0.0, 'isDefault': 1},
        {'name': '现金', 'icon': '💵', 'type': 'cash', 'balance': 0.0, 'isDefault': 1},
        {'name': '储蓄卡', 'icon': '🏦', 'type': 'bank', 'balance': 0.0, 'isDefault': 1},
        {'name': '信用卡', 'icon': '💳', 'type': 'credit', 'balance': 0.0, 'isDefault': 1},
        {'name': '蚂蚁花呗', 'icon': '🌸', 'type': 'credit', 'balance': 0.0, 'isDefault': 1},
        {'name': '京东白条', 'icon': '🐶', 'type': 'credit', 'balance': 0.0, 'isDefault': 1},
      ];
      for (final a in defaults) {
        await assetStore.add(db, a);
      }
    }
  }

  StoreRef<int, Map<String, Object?>> _categoryStore() {
    return intMapStoreFactory.store('categories');
  }

  StoreRef<int, Map<String, Object?>> _transactionStore() {
    return intMapStoreFactory.store('transactions');
  }

  StoreRef<int, Map<String, Object?>> _ledgerStore() {
    return intMapStoreFactory.store('ledgers');
  }

  StoreRef<int, Map<String, Object?>> _assetAccountStore() {
    return intMapStoreFactory.store('asset_accounts');
  }

  // ============ Categories ============

  Future<List<Category>> getCategories(String type) async {
    final db = await database;
    final records = await _categoryStore().find(
      db,
      finder: Finder(filter: Filter.equals('type', type)),
    );
    return records.map(_toCategory).toList();
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final records = await _categoryStore().find(db);
    return records.map(_toCategory).toList();
  }

  // ============ Transactions ============

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await _transactionStore().add(db, {
      'amount': transaction.amount,
      'type': transaction.type,
      'categoryId': transaction.categoryId,
      'categoryName': transaction.categoryName,
      'categoryIcon': transaction.categoryIcon,
      'note': transaction.note,
      'date': transaction.date,
      'createdAt': transaction.createdAt,
      'ledgerId': transaction.ledgerId,
    });
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    await _transactionStore().update(
      db,
      {
        'amount': transaction.amount,
        'type': transaction.type,
        'categoryId': transaction.categoryId,
        'categoryName': transaction.categoryName,
        'categoryIcon': transaction.categoryIcon,
        'note': transaction.note,
        'date': transaction.date,
        'createdAt': transaction.createdAt,
        'ledgerId': transaction.ledgerId,
      },
      finder: Finder(filter: Filter.equals(Field.key, transaction.id)),
    );
    return transaction.id!;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    await _transactionStore().delete(
      db,
      finder: Finder(filter: Filter.equals(Field.key, id)),
    );
    return id;
  }

  Future<List<Transaction>> getTransactions({
    String? type,
    String? startDate,
    String? endDate,
    int? categoryId,
    int? ledgerId,
  }) async {
    final db = await database;
    final filters = <Filter>[];

    if (type != null) filters.add(Filter.equals('type', type));
    if (categoryId != null) filters.add(Filter.equals('categoryId', categoryId));
    if (ledgerId != null) filters.add(Filter.equals('ledgerId', ledgerId));

    final records = await _transactionStore().find(
      db,
      finder: Finder(
        filter: filters.isEmpty ? null : Filter.and(filters),
      ),
    );

    var results = records.map(_toTransaction).toList();

    if (startDate != null) {
      results = results.where((t) => t.date.compareTo(startDate) >= 0).toList();
    }
    if (endDate != null) {
      results = results.where((t) => t.date.compareTo(endDate) <= 0).toList();
    }

    results.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return b.createdAt.compareTo(a.createdAt);
    });

    return results;
  }

  Future<List<Transaction>> getTransactionsByMonth(int year, int month,
      {int? ledgerId}) async {
    final monthStr = month.toString().padLeft(2, '0');
    final startDate = '$year-$monthStr-01';
    final endDate = '$year-$monthStr-31';
    return getTransactions(
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
    );
  }

  Future<Map<String, double>> getMonthlySummary(int year, int month,
      {int? ledgerId}) async {
    final txns = await getTransactionsByMonth(year, month, ledgerId: ledgerId);
    double income = 0;
    double expense = 0;
    for (final t in txns) {
      if (t.type == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return {'income': income, 'expense': expense};
  }

  Future<Map<String, double>> getCategorySummary(
    int year,
    int month,
    String type, {
    int? ledgerId,
  }) async {
    final allTxns = await getTransactionsByMonth(year, month, ledgerId: ledgerId);
    final filtered = allTxns.where((t) => t.type == type);
    final summary = <String, double>{};
    for (final t in filtered) {
      summary[t.categoryName] = (summary[t.categoryName] ?? 0) + t.amount;
    }
    return summary;
  }

  Future<Map<String, double>> getDailySummariesForMonth(int year, int month,
      {int? ledgerId}) async {
    final txns = await getTransactionsByMonth(year, month, ledgerId: ledgerId);
    final summary = <String, double>{};
    for (final t in txns) {
      summary[t.date] = (summary[t.date] ?? 0) + t.amount;
    }
    return summary;
  }

  Future<List<Transaction>> searchTransactions(String query) async {
    final db = await database;
    final records = await _transactionStore().find(db);
    final lower = query.toLowerCase();
    if (query.isEmpty) return [];
    return records
        .map(_toTransaction)
        .where((t) =>
            t.note.toLowerCase().contains(lower) ||
            t.categoryName.toLowerCase().contains(lower))
        .toList();
  }

  Future<int> getTransactionCountByLedger(int ledgerId) async {
    final db = await database;
    final records = await _transactionStore().find(
      db,
      finder: Finder(filter: Filter.equals('ledgerId', ledgerId)),
    );
    return records.length;
  }

  // ============ Ledgers ============

  Future<List<Ledger>> getLedgers() async {
    final db = await database;
    final records = await _ledgerStore().find(db);
    return records.map(_toLedger).toList();
  }

  Future<int> insertLedger(Ledger ledger) async {
    final db = await database;
    return await _ledgerStore().add(db, ledger.toMap());
  }

  Future<int> updateLedger(Ledger ledger) async {
    final db = await database;
    await _ledgerStore().update(
      db,
      ledger.toMap(),
      finder: Finder(filter: Filter.equals(Field.key, ledger.id)),
    );
    return ledger.id!;
  }

  Future<int> deleteLedger(int id) async {
    final db = await database;
    await _ledgerStore().delete(
      db,
      finder: Finder(filter: Filter.equals(Field.key, id)),
    );
    return id;
  }

  Future<Map<String, double>> getLedgerSummary(int ledgerId) async {
    final db = await database;
    final records = await _transactionStore().find(
      db,
      finder: Finder(filter: Filter.equals('ledgerId', ledgerId)),
    );
    double income = 0, expense = 0;
    for (final r in records) {
      final amount = (r['amount'] as num?)?.toDouble() ?? 0;
      if (r['type'] == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }
    return {'income': income, 'expense': expense};
  }

  // ============ Asset Accounts ============

  Future<List<AssetAccount>> getAssetAccounts() async {
    final db = await database;
    final records = await _assetAccountStore().find(db);
    return records.map(_toAssetAccount).toList();
  }

  Future<int> insertAssetAccount(AssetAccount account) async {
    final db = await database;
    return await _assetAccountStore().add(db, account.toMap());
  }

  Future<int> updateAssetAccount(AssetAccount account) async {
    final db = await database;
    await _assetAccountStore().update(
      db,
      account.toMap(),
      finder: Finder(filter: Filter.equals(Field.key, account.id)),
    );
    return account.id!;
  }

  Future<int> deleteAssetAccount(int id) async {
    final db = await database;
    await _assetAccountStore().delete(
      db,
      finder: Finder(filter: Filter.equals(Field.key, id)),
    );
    return id;
  }

  // ============ Converters ============

  Transaction _toTransaction(RecordSnapshot<int, Map<String, Object?>> r) {
    return Transaction(
      id: r.key,
      amount: (r['amount'] as num).toDouble(),
      type: r['type'] as String,
      categoryId: r['categoryId'] as int,
      categoryName: r['categoryName'] as String,
      categoryIcon: r['categoryIcon'] as String,
      note: r['note'] as String? ?? '',
      date: r['date'] as String,
      createdAt: r['createdAt'] as String?,
      ledgerId: r['ledgerId'] as int? ?? 1,
    );
  }

  Category _toCategory(RecordSnapshot<int, Map<String, Object?>> r) {
    return Category(
      id: r.key,
      name: r['name'] as String,
      icon: r['icon'] as String,
      type: r['type'] as String,
    );
  }

  Ledger _toLedger(RecordSnapshot<int, Map<String, Object?>> r) {
    return Ledger(
      id: r.key,
      name: r['name'] as String,
      icon: r['icon'] as String? ?? '📒',
      isDefault: (r['isDefault'] as int? ?? 0) == 1,
      sortOrder: r['sortOrder'] as int? ?? 0,
      createdAt: r['createdAt'] as String?,
    );
  }

  AssetAccount _toAssetAccount(RecordSnapshot<int, Map<String, Object?>> r) {
    return AssetAccount(
      id: r.key,
      name: r['name'] as String,
      icon: r['icon'] as String,
      type: r['type'] as String? ?? 'wallet',
      balance: (r['balance'] as num?)?.toDouble() ?? 0.0,
      isDefault: (r['isDefault'] as int? ?? 0) == 1,
    );
  }
}
