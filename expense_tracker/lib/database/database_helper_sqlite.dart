import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:path/path.dart' as p;
import 'dart:io';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/ledger.dart';
import '../models/asset_account.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> get _dbPath async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'expense_tracker.db');
  }

  Future<Database> _initDatabase() async {
    final path = await _dbPath;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    return await openDatabase(
      path,
      version: 2,
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
    await db.insert('ledgers', {
      'name': '个人账本',
      'icon': '📒',
      'isDefault': 1,
      'sortOrder': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _insertDefaultAssetAccounts(Database db) async {
    final batch = db.batch();
    final defaults = [
      {'name': '微信', 'icon': '💳', 'type': 'wallet', 'balance': 0.0},
      {'name': '支付宝', 'icon': '📱', 'type': 'wallet', 'balance': 0.0},
      {'name': '现金', 'icon': '💵', 'type': 'cash', 'balance': 0.0},
      {'name': '储蓄卡', 'icon': '🏦', 'type': 'bank', 'balance': 0.0},
      {'name': '信用卡', 'icon': '💳', 'type': 'credit', 'balance': 0.0},
      {'name': '蚂蚁花呗', 'icon': '🌸', 'type': 'credit', 'balance': 0.0},
      {'name': '京东白条', 'icon': '🐶', 'type': 'credit', 'balance': 0.0},
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
}
