// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqflite.dart' show getDatabasesPath; // ✅ إضافة هذا السطر
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/installment.dart';
import '../utils/constants.dart';

class DatabaseService {
  static sql.Database? _db;

  static Future<sql.Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<sql.Database> _initDb() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return await sql.openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(sql.Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.accountsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'USD',
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.transactionsTable} (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'USD',
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        category TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_frequency TEXT,
        recurring_end_date TEXT,
        is_installment INTEGER NOT NULL DEFAULT 0,
        installment_parent_id TEXT,
        installment_number INTEGER,
        total_installments INTEGER,
        attachment_path TEXT,
        FOREIGN KEY (account_id) REFERENCES ${AppConstants.accountsTable}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.installmentsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        total_amount REAL NOT NULL,
        number_of_installments INTEGER NOT NULL,
        installment_amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'USD',
        account_id TEXT NOT NULL,
        category TEXT NOT NULL,
        start_date TEXT NOT NULL,
        frequency TEXT NOT NULL DEFAULT 'monthly',
        paid_count INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES ${AppConstants.accountsTable}(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_account ON ${AppConstants.transactionsTable}(account_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_date ON ${AppConstants.transactionsTable}(date);
    ''');
  }

  static Future<void> _onUpgrade(sql.Database db, int oldVersion, int newVersion) async {
    // Handle future migrations
  }

  // ─── Accounts ───────────────────────────────────────────────────────────────

  static Future<String> insertAccount(Account account) async {
    final db = await database;
    await db.insert(AppConstants.accountsTable, account.toMap(),
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return account.id;
  }

  static Future<List<Account>> getAccounts({bool activeOnly = true}) async {
    final db = await database;
    final where = activeOnly ? 'WHERE is_active = 1' : '';
    final maps = await db
        .rawQuery('SELECT * FROM ${AppConstants.accountsTable} $where ORDER BY created_at ASC');
    return maps.map((m) => Account.fromMap(m)).toList();
  }

  static Future<Account?> getAccountById(String id) async {
    final db = await database;
    final maps = await db.query(AppConstants.accountsTable,
        where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  static Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update(AppConstants.accountsTable, account.toMap(),
        where: 'id = ?', whereArgs: [account.id]);
  }

  static Future<void> updateAccountBalance(String id, double newBalance) async {
    final db = await database;
    await db.update(
      AppConstants.accountsTable,
      {'balance': newBalance, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.update(
      AppConstants.accountsTable,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Transactions ───────────────────────────────────────────────────────────

  static Future<String> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert(AppConstants.transactionsTable, transaction.toMap(),
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return transaction.id;
  }

  static Future<List<Transaction>> getTransactions({
    String? accountId,
    DateTime? from,
    DateTime? to,
    String? type,
    int? limit,
    int offset = 0,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (accountId != null) {
      conditions.add('(account_id = ? OR to_account_id = ?)');
      args.addAll([accountId, accountId]);
    }
    if (from != null) {
      conditions.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      conditions.add('date <= ?');
      args.add(to.toIso8601String());
    }
    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final limitClause = limit != null ? 'LIMIT $limit OFFSET $offset' : '';

    final maps = await db.rawQuery(
      'SELECT * FROM ${AppConstants.transactionsTable} $where ORDER BY date DESC $limitClause',
      args,
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    final db = await database;
    await db.update(AppConstants.transactionsTable, transaction.toMap(),
        where: 'id = ?', whereArgs: [transaction.id]);
  }

  static Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(AppConstants.transactionsTable,
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, double>> getSummary({
    String? accountId,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (accountId != null) {
      conditions.add('account_id = ?');
      args.add(accountId);
    }
    if (from != null) {
      conditions.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      conditions.add('date <= ?');
      args.add(to.toIso8601String());
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as total_expense
      FROM ${AppConstants.transactionsTable} $where
    ''', args);

    if (result.isEmpty) return {'income': 0, 'expense': 0};
    return {
      'income': (result.first['total_income'] as num?)?.toDouble() ?? 0,
      'expense': (result.first['total_expense'] as num?)?.toDouble() ?? 0,
    };
  }

  static Future<Map<String, double>> getExpensesByCategory({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    final conditions = ["type = 'expense'"];
    final args = <dynamic>[];

    if (from != null) {
      conditions.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      conditions.add('date <= ?');
      args.add(to.toIso8601String());
    }

    final where = 'WHERE ${conditions.join(' AND ')}';
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM ${AppConstants.transactionsTable} $where
      GROUP BY category
      ORDER BY total DESC
    ''', args);

    return {
      for (final row in result)
        row['category'] as String: (row['total'] as num).toDouble()
    };
  }

  // ─── Installments ───────────────────────────────────────────────────────────

  static Future<String> insertInstallment(Installment inst) async {
    final db = await database;
    await db.insert(AppConstants.installmentsTable, inst.toMap(),
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return inst.id;
  }

  static Future<List<Installment>> getInstallments({bool activeOnly = true}) async {
    final db = await database;
    final where = activeOnly ? 'WHERE is_completed = 0' : '';
    final maps = await db.rawQuery(
        'SELECT * FROM ${AppConstants.installmentsTable} $where ORDER BY start_date ASC');
    return maps.map((m) => Installment.fromMap(m)).toList();
  }

  static Future<void> updateInstallment(Installment inst) async {
    final db = await database;
    await db.update(AppConstants.installmentsTable, inst.toMap(),
        where: 'id = ?', whereArgs: [inst.id]);
  }

  static Future<void> deleteInstallment(String id) async {
    final db = await database;
    await db.delete(AppConstants.installmentsTable,
        where: 'id = ?', whereArgs: [id]);
  }

  // ─── Backup / Restore ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    final accounts = await db.query(AppConstants.accountsTable);
    final transactions = await db.query(AppConstants.transactionsTable);
    final installments = await db.query(AppConstants.installmentsTable);
    return {
      'accounts': accounts,
      'transactions': transactions,
      'installments': installments,
      'exported_at': DateTime.now().toIso8601String(),
      'version': AppConstants.dbVersion,
    };
  }

  static Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((sql.Transaction txn) async {
      await txn.delete(AppConstants.installmentsTable);
      await txn.delete(AppConstants.transactionsTable);
      await txn.delete(AppConstants.accountsTable);

      final accounts = data['accounts'] as List<dynamic>;
      for (final a in accounts) {
        await txn.insert(AppConstants.accountsTable, Map<String, dynamic>.from(a as Map),
            conflictAlgorithm: sql.ConflictAlgorithm.replace);
      }

      final transactions = data['transactions'] as List<dynamic>;
      for (final t in transactions) {
        await txn.insert(AppConstants.transactionsTable, Map<String, dynamic>.from(t as Map),
            conflictAlgorithm: sql.ConflictAlgorithm.replace);
      }

      final installments = data['installments'] as List<dynamic>;
      for (final i in installments) {
        await txn.insert(AppConstants.installmentsTable, Map<String, dynamic>.from(i as Map),
            conflictAlgorithm: sql.ConflictAlgorithm.replace);
      }
    });
  }
}
