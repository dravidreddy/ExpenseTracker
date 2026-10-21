import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/expense.dart';

class DatabaseHelper {
  static const _dbName = 'antigravity.db';
  static const _dbVersion = 2;
  static const _tableName = 'expenses';
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<String> _getEncryptionKey(String path) async {
    const storage = FlutterSecureStorage();
    String? key = await storage.read(key: 'db_encryption_key');
    final dbFileExists = await databaseExists(path);

    if (key == null) {
      if (dbFileExists) {
        // Guard against silent database corruption:
        // If DB exists but Keystore was cleared, generating a new random key
        // will cause SQLCipher to fail with "file is not a database".
        throw StateError(
          'Security Keystore reset detected: The database exists but the encryption key could not be recovered.',
        );
      }
      final random = Random.secure();
      final bytes = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64UrlEncode(bytes);
      await storage.write(key: 'db_encryption_key', value: key);
    }
    return key;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    final password = await _getEncryptionKey(path);
    
    return openDatabase(
      path,
      password: password,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        amount    REAL    NOT NULL,
        description TEXT  NOT NULL,
        category  TEXT    NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_timestamp ON $_tableName (timestamp DESC)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration strategy for future schema changes
    if (oldVersion < 2) {
      // Example: await db.execute('ALTER TABLE $_tableName ADD COLUMN tags TEXT');
    }
  }



  // ── CRUD ──────────────────────────────────────────────────────────────

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert(_tableName, expense.toMap());
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return db.update(
      _tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  // ── Queries ───────────────────────────────────────────────────────────

  /// All expenses for a specific calendar date (local time).
  Future<List<Expense>> getExpensesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day + 1).millisecondsSinceEpoch;

    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start, end],
      orderBy: 'timestamp DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  /// Sum of all expenses logged on a specific date (local time).
  Future<double> getTotalForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day + 1).millisecondsSinceEpoch;

    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0.0) AS total '
      'FROM $_tableName '
      'WHERE timestamp >= ? AND timestamp < ?',
      [start, end],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Sum of all expenses logged today (local time).
  Future<double> getTodayTotal() => getTotalForDate(DateTime.now());

  // ── Month-by-Month (Timeline View) ────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMonthlyTotals() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        CAST(strftime('%Y', datetime(timestamp/1000, 'unixepoch', 'localtime')) AS INTEGER) AS year,
        CAST(strftime('%m', datetime(timestamp/1000, 'unixepoch', 'localtime')) AS INTEGER) AS month,
        SUM(amount) AS total
      FROM $_tableName
      GROUP BY year, month
      ORDER BY year DESC, month DESC
    ''');
  }

  // ── Date Drill-Down (Dates within a Month) ─────────────────────────────

  Future<List<Map<String, dynamic>>> getDailyTotalsForMonth(
      int year, int month) async {
    final start = DateTime(year, month).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1).millisecondsSinceEpoch;

    final db = await database;
    return db.rawQuery('''
      SELECT
        CAST(strftime('%d', datetime(timestamp/1000, 'unixepoch', 'localtime')) AS INTEGER) AS day,
        SUM(amount) AS total,
        MIN(timestamp) AS ts_sample
      FROM $_tableName
      WHERE timestamp >= ? AND timestamp < ?
      GROUP BY day
      ORDER BY day DESC
    ''', [start, end]);
  }

  /// Wipes all expense records from the database.
  Future<int> clearAllData() async {
    final db = await database;
    return db.delete(_tableName);
  }
}

