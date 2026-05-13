import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:path/path.dart' as p;
import 'dart:io';
import '../models/transaction.dart';
import '../models/category.dart';
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
          version: 1,
          onCreate: _onCreate,
        ),
      );
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
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
        createdAt TEXT NOT NULL
      )
    ''');

    await _insertDefaultCategories(db);
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

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
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

    final maps = await db.query(
      'transactions',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await database;
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';

    final result = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM transactions
      WHERE date LIKE '$monthStr%'
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
    String type,
  ) async {
    final db = await database;
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';

    final result = await db.rawQuery('''
      SELECT categoryName, SUM(amount) as total
      FROM transactions
      WHERE date LIKE '$monthStr%' AND type = '$type'
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
}
