import 'package:sembast_web/sembast_web.dart' hide Transaction;
import '../models/transaction.dart';
import '../models/category.dart';
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
    final count = await catStore.count(db);
    if (count == 0) {
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
  }

  StoreRef<int, Map<String, Object?>> _categoryStore() {
    return intMapStoreFactory.store('categories');
  }

  StoreRef<int, Map<String, Object?>> _transactionStore() {
    return intMapStoreFactory.store('transactions');
  }

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
  }) async {
    final db = await database;
    final filters = <Filter>[];

    if (type != null) filters.add(Filter.equals('type', type));
    if (categoryId != null) filters.add(Filter.equals('categoryId', categoryId));

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

  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final monthStr = month.toString().padLeft(2, '0');
    final startDate = '$year-$monthStr-01';
    final endDate = '$year-$monthStr-31';
    return getTransactions(startDate: startDate, endDate: endDate);
  }

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final txns = await getTransactionsByMonth(year, month);
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
    String type,
  ) async {
    final allTxns = await getTransactionsByMonth(year, month);
    final filtered = allTxns.where((t) => t.type == type);
    final summary = <String, double>{};
    for (final t in filtered) {
      summary[t.categoryName] = (summary[t.categoryName] ?? 0) + t.amount;
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
}
