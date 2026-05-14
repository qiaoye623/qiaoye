import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'dart:ffi';
import 'dart:io';
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

  static Database? _database;
  static Future<Database>? _initFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _initFuture ??= _initDatabase();
    _database = await _initFuture;
    return _database!;
  }

  Future<String> get _dbPath async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'expense_tracker.db');
  }

  Future<Database> _initDatabase() async {
    final path = await _dbPath;

    if (Platform.isWindows || Platform.isLinux) {
      // Windows release mode: sqfliteFfiInit can't find the bundled sqlite3.dll
      // via pubspec.lock, so we register the override explicitly to load from
      // the executable directory (where users must place sqlite3.dll)
      if (Platform.isWindows) {
        open.overrideFor(OperatingSystem.windows, () {
          return DynamicLibrary.open('sqlite3.dll');
        });
      }
      sqfliteFfiInit();
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 8,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        categoryName TEXT NOT NULL,
        categoryIcon TEXT NOT NULL,
        note TEXT DEFAULT '',
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        ledgerId INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ledgers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT '📒',
        isDefault INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        isDefault INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE save_plans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        start_amount REAL NOT NULL DEFAULT 0,
        duration_days INTEGER NOT NULL DEFAULT 0,
        increment_coeff REAL NOT NULL DEFAULT 0,
        month_amount REAL NOT NULL DEFAULT 0,
        total_target REAL NOT NULL DEFAULT 0,
        current_amount REAL NOT NULL DEFAULT 0,
        icon_code INTEGER NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        created_at TEXT,
        status TEXT NOT NULL DEFAULT 'active'
      )
    ''');

    await db.execute('''
      CREATE TABLE save_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL REFERENCES save_plans(id) ON DELETE CASCADE,
        sequence_index INTEGER NOT NULL,
        target_amount REAL NOT NULL DEFAULT 0,
        saved_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        saved_date TEXT,
        created_at TEXT
      )
    ''');

    await _insertDefaultCategories(db);
    await _insertDefaultLedger(db);
    await _insertDefaultAssetAccounts(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE transactions ADD COLUMN ledgerId INTEGER NOT NULL DEFAULT 1");

      await db.execute('''
        CREATE TABLE ledgers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT NOT NULL DEFAULT '📒',
          isDefault INTEGER NOT NULL DEFAULT 0,
          sortOrder INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE asset_accounts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          type TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0.0,
          isDefault INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await _insertDefaultLedger(db);
      await _insertDefaultAssetAccounts(db);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE save_plans(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          start_amount REAL NOT NULL DEFAULT 0,
          duration_days INTEGER NOT NULL DEFAULT 0,
          increment_coeff REAL NOT NULL DEFAULT 0,
          month_amount REAL NOT NULL DEFAULT 0,
          total_target REAL NOT NULL DEFAULT 0,
          current_amount REAL NOT NULL DEFAULT 0,
          icon_code INTEGER NOT NULL DEFAULT 0,
          start_date TEXT NOT NULL,
          created_at TEXT,
          status TEXT NOT NULL DEFAULT 'active'
        )
      ''');

      await db.execute('''
        CREATE TABLE save_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plan_id INTEGER NOT NULL REFERENCES save_plans(id) ON DELETE CASCADE,
          sequence_index INTEGER NOT NULL,
          target_amount REAL NOT NULL DEFAULT 0,
          saved_amount REAL NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'pending',
          saved_date TEXT,
          created_at TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
          "ALTER TABLE save_plans ADD COLUMN month_amount REAL NOT NULL DEFAULT 0");
    }
    if (oldVersion < 5) {
      await db.execute('''
        DELETE FROM asset_accounts WHERE id NOT IN (
          SELECT MIN(id) FROM asset_accounts GROUP BY name
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        DELETE FROM asset_accounts WHERE id NOT IN (
          SELECT MIN(id) FROM asset_accounts GROUP BY name
        )
      ''');
      await db.execute('''
        DELETE FROM asset_accounts WHERE isDefault = 1
        AND name NOT IN ('微信', '支付宝', '现金')
      ''');
      await db.execute('''
        UPDATE asset_accounts SET name = '微信钱包', icon = '💳'
        WHERE name = '微信' AND isDefault = 1
      ''');
      await db.execute('''
        UPDATE asset_accounts SET name = '支付宝钱包', icon = '📱'
        WHERE name = '支付宝' AND isDefault = 1
      ''');
      await db.execute('''
        DELETE FROM ledgers WHERE id NOT IN (
          SELECT MIN(id) FROM ledgers GROUP BY name
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE transactions ADD COLUMN accountId INTEGER');
    }
    if (oldVersion < 8) {
      // 清空所有数据并重建
      await db.execute('DROP TABLE IF EXISTS save_records');
      await db.execute('DROP TABLE IF EXISTS save_plans');
      await db.execute('DROP TABLE IF EXISTS asset_accounts');
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS ledgers');
      await db.execute('DROP TABLE IF EXISTS categories');
      await _onCreate(db, 8);
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final batch = db.batch();
    for (final cat in DefaultCategories.expense) {
      batch.insert('categories', {
        'name': cat['name'],
        'icon': cat['icon'],
        'type': 'expense',
      });
    }
    for (final cat in DefaultCategories.income) {
      batch.insert('categories', {
        'name': cat['name'],
        'icon': cat['icon'],
        'type': 'income',
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> _insertDefaultLedger(Database db) async {
    // 清理同名重复账本（同名只保留 id 最小的那条）
    await db.execute('''
      DELETE FROM ledgers WHERE id NOT IN (
        SELECT MIN(id) FROM ledgers GROUP BY name
      )
    ''');
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM ledgers');
    if ((result.first['c'] as int) > 0) return;
    await db.insert('ledgers', {
      'name': '个人账本',
      'icon': '📒',
      'isDefault': 1,
      'sortOrder': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _insertDefaultAssetAccounts(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM asset_accounts');
    if ((result.first['c'] as int) > 0) return;

    final batch = db.batch();
    final defaults = [
      {'name': '微信钱包', 'icon': '💳', 'type': 'wallet', 'balance': 0.0},
      {'name': '支付宝钱包', 'icon': '📱', 'type': 'wallet', 'balance': 0.0},
      {'name': '现金', 'icon': '💵', 'type': 'cash', 'balance': 0.0},
    ];
    for (final a in defaults) {
      batch.insert('asset_accounts', {
        ...a,
        'isDefault': 1,
      });
    }
    await batch.commit(noResult: true);
  }

  // ============ Categories ============

  Future<List<Category>> getCategories(String type) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'id ASC',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'id ASC');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', {
      'name': category.name,
      'icon': category.icon,
      'type': category.type,
    });
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      {'name': category.name, 'icon': category.icon, 'type': category.type},
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Transactions ============

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Transaction>> getTransactions({
    String? type,
    String? startDate,
    String? endDate,
    int? categoryId,
    int? ledgerId,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.add('date <= ?');
      args.add(endDate);
    }
    if (categoryId != null) {
      where.add('categoryId = ?');
      args.add(categoryId);
    }
    if (ledgerId != null) {
      where.add('ledgerId = ?');
      args.add(ledgerId);
    }

    final maps = await db.query(
      'transactions',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
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
    final db = await database;
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final where = "date LIKE '$monthStr%'";
    final finalWhere =
        ledgerId != null ? "$where AND ledgerId = $ledgerId" : where;

    final result = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM transactions
      WHERE $finalWhere
      GROUP BY type
    ''');

    double income = 0;
    double expense = 0;
    for (final row in result) {
      if (row['type'] == 'income') {
        income = (row['total'] as num).toDouble();
      } else {
        expense = (row['total'] as num).toDouble();
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
    final db = await database;
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final ledgerFilter =
        ledgerId != null ? " AND ledgerId = $ledgerId" : "";

    final result = await db.rawQuery('''
      SELECT categoryName, SUM(amount) as total
      FROM transactions
      WHERE date LIKE '$monthStr%' AND type = '$type'$ledgerFilter
      GROUP BY categoryName
      ORDER BY total DESC
    ''');

    final summary = <String, double>{};
    for (final row in result) {
      summary[row['categoryName'] as String] =
          (row['total'] as num).toDouble();
    }
    return summary;
  }

  Future<Map<String, double>> getDailySummariesForMonth(int year, int month,
      {int? ledgerId}) async {
    final db = await database;
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final where = "date LIKE '$monthStr%'";
    final finalWhere =
        ledgerId != null ? "$where AND ledgerId = $ledgerId" : where;

    final result = await db.rawQuery('''
      SELECT date, SUM(amount) as total
      FROM transactions
      WHERE $finalWhere
      GROUP BY date
      ORDER BY date ASC
    ''');

    final summary = <String, double>{};
    for (final row in result) {
      summary[row['date'] as String] = (row['total'] as num).toDouble();
    }
    return summary;
  }

  Future<List<Transaction>> searchTransactions(String query) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'note LIKE ? OR categoryName LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<int> getTransactionCountByLedger(int ledgerId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM transactions WHERE ledgerId = ?',
        [ledgerId]);
    return (result.first['count'] as int?) ?? 0;
  }

  // ============ Ledgers ============

  Future<List<Ledger>> getLedgers() async {
    final db = await database;
    final maps =
        await db.query('ledgers', orderBy: 'sortOrder ASC, id ASC');
    return maps.map((map) => Ledger.fromMap(map)).toList();
  }

  Future<int> insertLedger(Ledger ledger) async {
    final db = await database;
    return await db.insert('ledgers', ledger.toMap());
  }

  Future<int> updateLedger(Ledger ledger) async {
    final db = await database;
    return await db.update(
      'ledgers',
      ledger.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [ledger.id],
    );
  }

  Future<void> setDefaultLedger(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('ledgers', {'isDefault': 0});
      await txn.update('ledgers', {'isDefault': 1}, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> deleteLedger(int id) async {
    final db = await database;
    return await db.delete('ledgers', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getLedgerSummary(int ledgerId) async {
    final db = await database;
    final incResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE ledgerId = ? AND type = ?',
      [ledgerId, 'income'],
    );
    final expResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE ledgerId = ? AND type = ?',
      [ledgerId, 'expense'],
    );
    final income = (incResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final expense = (expResult.first['total'] as num?)?.toDouble() ?? 0.0;
    return {'income': income, 'expense': expense};
  }

  // ============ Asset Accounts ============

  Future<List<AssetAccount>> getAssetAccounts() async {
    final db = await database;
    final maps = await db.query('asset_accounts', orderBy: 'id ASC');
    return maps.map((map) => AssetAccount.fromMap(map)).toList();
  }

  Future<int> insertAssetAccount(AssetAccount account) async {
    final db = await database;
    return await db.insert('asset_accounts', account.toMap());
  }

  Future<int> updateAssetAccount(AssetAccount account) async {
    final db = await database;
    return await db.update(
      'asset_accounts',
      account.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAssetAccount(int id) async {
    final db = await database;
    return await db
        .delete('asset_accounts', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Save Plans ============

  Future<List<SavePlan>> getSavePlans() async {
    final db = await database;
    final maps =
        await db.query('save_plans', orderBy: 'created_at DESC');
    return maps.map((map) => SavePlan.fromMap(map)).toList();
  }

  Future<SavePlan?> getSavePlanById(int id) async {
    final db = await database;
    final maps = await db.query('save_plans',
        where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return SavePlan.fromMap(maps.first);
  }

  Future<int> insertSavePlan(SavePlan plan) async {
    final db = await database;
    return await db.insert('save_plans', plan.toMap());
  }

  Future<void> updateSavePlan(SavePlan plan) async {
    final db = await database;
    await db.update(
      'save_plans',
      plan.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<void> deleteSavePlan(int id) async {
    final db = await database;
    await db.delete('save_plans', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Save Records ============

  Future<List<SaveRecord>> getSaveRecords(int planId) async {
    final db = await database;
    final maps = await db.query('save_records',
        where: 'plan_id = ?',
        whereArgs: [planId],
        orderBy: 'sequence_index ASC');
    return maps.map((map) => SaveRecord.fromMap(map)).toList();
  }

  Future<SaveRecord?> getSaveRecordById(int id) async {
    final db = await database;
    final maps = await db.query('save_records',
        where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return SaveRecord.fromMap(maps.first);
  }

  Future<void> insertSaveRecord(SaveRecord record) async {
    final db = await database;
    await db.insert('save_records', record.toMap());
  }

  Future<void> batchInsertSaveRecords(List<SaveRecord> records) async {
    final db = await database;
    final batch = db.batch();
    for (final r in records) {
      batch.insert('save_records', r.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateSaveRecord(SaveRecord record) async {
    final db = await database;
    await db.update(
      'save_records',
      record.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteSaveRecordsByPlanId(int planId) async {
    final db = await database;
    await db.delete('save_records',
        where: 'plan_id = ?', whereArgs: [planId]);
  }
}
