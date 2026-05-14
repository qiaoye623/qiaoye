import 'package:sembast_web/sembast_web.dart' hide Transaction;
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/ledger.dart';
import '../models/asset_account.dart';
import '../models/save_plan.dart';
import '../models/save_record.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;
  Future<Database>? _initFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _initFuture ??= _initDatabase();
    _database = await _initFuture;
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
    // 清理同名重复账本
    final allLedgers = await ledgerStore.find(db);
    final seenLedgers = <String, int>{};
    for (final r in allLedgers) {
      final name = r['name'] as String? ?? '';
      if (seenLedgers.containsKey(name)) {
        await ledgerStore.delete(db,
            finder: Finder(filter: Filter.equals(Field.key, r.key)));
      } else {
        seenLedgers[name] = r.key;
      }
    }
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
        {'name': '微信钱包', 'icon': '💳', 'type': 'wallet', 'balance': 0.0, 'isDefault': 1},
        {'name': '支付宝钱包', 'icon': '📱', 'type': 'wallet', 'balance': 0.0, 'isDefault': 1},
        {'name': '现金', 'icon': '💵', 'type': 'cash', 'balance': 0.0, 'isDefault': 1},
      ];
      for (final a in defaults) {
        await assetStore.add(db, a);
      }
    } else {
      await _migrateAssetAccountsWeb(db, assetStore);
    }
  }

  Future<void> _migrateAssetAccountsWeb(
      Database db, StoreRef<int, Map<String, Object?>> store) async {
    final all = await store.find(db);

    // Step 1: 去重 — 同名资产只保留 id 最小的那条
    final seen = <String, int>{};
    final toDelete = <int>{};
    // 先重命名旧名称，再统一去重
    for (final r in all) {
      final name = r['name'] as String? ?? '';
      final resolved = name == '微信' ? '微信钱包' : name == '支付宝' ? '支付宝钱包' : name;
      if (seen.containsKey(resolved)) {
        toDelete.add(r.key);
      } else {
        seen[resolved] = r.key;
      }
    }
    for (final key in toDelete) {
      await store.delete(db, finder: Finder(filter: Filter.equals(Field.key, key)));
    }

    // Step 2: 重命名旧名称（微信→微信钱包, 支付宝→支付宝钱包）
    // 重新获取，因为去重后 record 可能已变
    final afterDedup = await store.find(db);
    for (final r in afterDedup) {
      final name = r['name'] as String? ?? '';
      if (name == '微信') {
        await store.update(db, {'name': '微信钱包'},
            finder: Finder(filter: Filter.equals(Field.key, r.key)));
      } else if (name == '支付宝') {
        await store.update(db, {'name': '支付宝钱包'},
            finder: Finder(filter: Filter.equals(Field.key, r.key)));
      }
    }

    // Step 3: 删除非基础默认账户
    final toClean = await store.find(db);
    for (final r in toClean) {
      final name = r['name'] as String? ?? '';
      if (r['isDefault'] == 1 &&
          !['微信钱包', '支付宝钱包', '现金'].contains(name)) {
        await store.delete(db,
            finder: Finder(filter: Filter.equals(Field.key, r.key)));
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

  StoreRef<int, Map<String, Object?>> _savePlanStore() {
    return intMapStoreFactory.store('save_plans');
  }

  StoreRef<int, Map<String, Object?>> _saveRecordStore() {
    return intMapStoreFactory.store('save_records');
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

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await _categoryStore().add(db, {
      'name': category.name,
      'icon': category.icon,
      'type': category.type,
    });
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    await _categoryStore().update(
      db,
      {'name': category.name, 'icon': category.icon, 'type': category.type},
      finder: Finder(filter: Filter.equals(Field.key, category.id)),
    );
    return category.id!;
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    await _categoryStore().delete(
      db,
      finder: Finder(filter: Filter.equals(Field.key, id)),
    );
    return id;
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
      'accountId': transaction.accountId,
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
        'accountId': transaction.accountId,
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

  Future<void> setDefaultLedger(int id) async {
    final db = await database;
    final all = await _ledgerStore().find(db);
    for (final r in all) {
      if (r.key == id || r.value['isDefault'] == 1) {
        await _ledgerStore().update(db, {'isDefault': r.key == id ? 1 : 0},
            finder: Finder(filter: Filter.equals(Field.key, r.key)));
      }
    }
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

  // ============ Save Plans ============

  Future<List<SavePlan>> getSavePlans() async {
    final db = await database;
    final records = await _savePlanStore().find(db);
    return records
        .map((r) => SavePlan.fromMap(r.value, id: r.key))
        .toList()
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
  }

  Future<SavePlan?> getSavePlanById(int id) async {
    final db = await database;
    final records = await _savePlanStore().find(
      db,
      finder: Finder(filter: Filter.equals(Field.key, id)),
    );
    if (records.isEmpty) return null;
    return SavePlan.fromMap(records.first.value, id: records.first.key);
  }

  Future<int> insertSavePlan(SavePlan plan) async {
    final db = await database;
    return await _savePlanStore().add(db, plan.toMap());
  }

  Future<void> updateSavePlan(SavePlan plan) async {
    final db = await database;
    await _savePlanStore().update(
      db,
      plan.toMap(),
      finder: Finder(filter: Filter.equals(Field.key, plan.id)),
    );
  }

  Future<void> deleteSavePlan(int id) async {
    final db = await database;
    await _savePlanStore().delete(
      db,
      finder: Finder(filter: Filter.equals(Field.key, id)),
    );
    // cascade delete records
    await _saveRecordStore().delete(
      db,
      finder: Finder(filter: Filter.equals('plan_id', id)),
    );
  }

  // ============ Save Records ============

  Future<List<SaveRecord>> getSaveRecords(int planId) async {
    final db = await database;
    final records = await _saveRecordStore().find(
      db,
      finder: Finder(filter: Filter.equals('plan_id', planId)),
    );
    final result = records
        .map((r) => SaveRecord.fromMap(r.value, id: r.key))
        .toList();
    result.sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    return result;
  }

  Future<SaveRecord?> getSaveRecordById(int id) async {
    final db = await database;
    final records = await _saveRecordStore().find(
      db,
      finder: Finder(filter: Filter.equals(Field.key, id)),
    );
    if (records.isEmpty) return null;
    return SaveRecord.fromMap(records.first.value, id: records.first.key);
  }

  Future<void> insertSaveRecord(SaveRecord record) async {
    final db = await database;
    await _saveRecordStore().add(db, record.toMap());
  }

  Future<void> batchInsertSaveRecords(List<SaveRecord> records) async {
    final db = await database;
    for (final r in records) {
      await _saveRecordStore().add(db, r.toMap());
    }
  }

  Future<void> updateSaveRecord(SaveRecord record) async {
    final db = await database;
    await _saveRecordStore().update(
      db,
      record.toMap(),
      finder: Finder(filter: Filter.equals(Field.key, record.id)),
    );
  }

  Future<void> deleteSaveRecordsByPlanId(int planId) async {
    final db = await database;
    await _saveRecordStore().delete(
      db,
      finder: Finder(filter: Filter.equals('plan_id', planId)),
    );
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
      accountId: r['accountId'] as int?,
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
