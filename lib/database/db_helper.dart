import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('goat_fish_farming.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE investors (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        business_type TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        investor_id TEXT,
        investor_name TEXT,
        payment_method TEXT,
        description TEXT,
        receipt_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.insert('settings', {'key': 'business_name', 'value': 'Goat & Fish Farming Business'});
    await db.insert('settings', {'key': 'currency', 'value': '₹'});
    await db.insert('settings', {'key': 'start_date', 'value': DateTime.now().toIso8601String()});

    final List<String> initialInvestors = [
      'Kausar Alom',
      'Ruhal',
      'Shahnaaz',
      'Babu',
      'Imrul',
      'Firoz',
    ];

    final now = DateTime.now().toIso8601String();
    for (String name in initialInvestors) {
      await db.insert('investors', {
        'id': const Uuid().v4(),
        'name': name,
        'phone': '',
        'notes': 'Founding Member',
        'is_active': 1,
        'created_at': now,
      });
    }
  }

  Future<List<Investor>> getInvestors({bool activeOnly = true}) async {
    final db = await database;
    final where = activeOnly ? 'is_active = 1' : null;
    final result = await db.query('investors', where: where, orderBy: 'name ASC');
    return result.map((json) => Investor.fromMap(json)).toList();
  }

  Future<int> insertInvestor(Investor investor) async {
    final db = await database;
    return await db.insert('investors', investor.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> updateInvestor(Investor investor) async {
    final db = await database;
    await db.update(
      'transactions',
      {'investor_name': investor.name},
      where: 'investor_id = ?',
      whereArgs: [investor.id],
    );
    return await db.update(
      'investors',
      investor.toMap(),
      where: 'id = ?',
      whereArgs: [investor.id],
    );
  }

  Future<int> deleteInvestor(String id) async {
    final db = await database;
    return await db.update(
      'investors',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getTransactions({
    String? type,
    String? businessType,
    String? investorId,
    String? startDate,
    String? endDate,
    String? searchQuery,
  }) async {
    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (type != null && type.isNotEmpty && type != 'All') {
      whereClauses.add('type = ?');
      whereArgs.add(type.toLowerCase());
    }

    if (businessType != null && businessType.isNotEmpty && businessType != 'All') {
      whereClauses.add('business_type = ?');
      whereArgs.add(businessType);
    }

    if (investorId != null && investorId.isNotEmpty && investorId != 'All') {
      whereClauses.add('investor_id = ?');
      whereArgs.add(investorId);
    }

    if (startDate != null && startDate.isNotEmpty) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate);
    }

    if (endDate != null && endDate.isNotEmpty) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR category LIKE ? OR description LIKE ? OR investor_name LIKE ?)');
      final term = '%$searchQuery%';
      whereArgs.addAll([term, term, term, term]);
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final result = await db.query('transactions', where: where, whereArgs: whereArgs, orderBy: 'date DESC, created_at DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final db = await database;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final monthPrefix = DateFormat('yyyy-MM').format(now);

    final allTx = await db.query('transactions');

    double totalInv = 0, totalExp = 0, totalInc = 0;
    double goatInv = 0, fishInv = 0, commonInv = 0;
    double goatExp = 0, fishExp = 0, commonExp = 0;
    double goatInc = 0, fishInc = 0, commonInc = 0;
    double todayInv = 0, todayExp = 0;
    double monthInv = 0, monthExp = 0;

    for (var row in allTx) {
      final type = row['type'] as String;
      final bType = row['business_type'] as String;
      final amt = (row['amount'] as num).toDouble();
      final date = row['date'] as String;

      if (type == 'investment') {
        totalInv += amt;
        if (bType == 'Goat') goatInv += amt;
        if (bType == 'Fish') fishInv += amt;
        if (bType == 'Common') commonInv += amt;

        if (date == todayStr) todayInv += amt;
        if (date.startsWith(monthPrefix)) monthInv += amt;
      } else if (type == 'expense') {
        totalExp += amt;
        if (bType == 'Goat') goatExp += amt;
        if (bType == 'Fish') fishExp += amt;
        if (bType == 'Common') commonExp += amt;

        if (date == todayStr) todayExp += amt;
        if (date.startsWith(monthPrefix)) monthExp += amt;
      } else if (type == 'income') {
        totalInc += amt;
        if (bType == 'Goat') goatInc += amt;
        if (bType == 'Fish') fishInc += amt;
        if (bType == 'Common') commonInc += amt;
      }
    }

    final double balance = totalInv + totalInc - totalExp;
    final double netProfitLoss = totalInc - totalExp;

    return DashboardSummary(
      totalInvestment: totalInv,
      totalExpense: totalExp,
      totalIncome: totalInc,
      remainingBalance: balance,
      netProfitLoss: netProfitLoss,
      goatInvestment: goatInv,
      fishInvestment: fishInv,
      commonInvestment: commonInv,
      goatExpense: goatExp,
      fishExpense: fishExp,
      commonExpense: commonExp,
      goatIncome: goatInc,
      fishIncome: fishInc,
      commonIncome: commonInc,
      todayInvestment: todayInv,
      todayExpense: todayExp,
      monthlyInvestment: monthInv,
      monthlyExpense: monthExp,
    );
  }

  Future<Map<String, double>> getInvestorContributions() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT investor_id, SUM(amount) as total 
      FROM transactions 
      WHERE type = 'investment' 
      GROUP BY investor_id
    ''');

    Map<String, double> map = {};
    for (var r in result) {
      final id = r['investor_id'] as String?;
      if (id != null) {
        map[id] = (r['total'] as num).toDouble();
      }
    }
    return map;
  }

  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final db = await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) return res.first['value'] as String;
    return defaultValue;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> exportBackupJson() async {
    final db = await database;
    final investors = await db.query('investors');
    final transactions = await db.query('transactions');
    final settings = await db.query('settings');

    final backupData = {
      'app': 'GOAT_AND_FISH_FARMING_BUSINESS',
      'version': '1.0.0',
      'export_date': DateTime.now().toIso8601String(),
      'investors': investors,
      'transactions': transactions,
      'settings': settings,
    };

    return jsonEncode(backupData);
  }

  Map<String, dynamic>? validateBackupContent(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic> &&
          decoded['app'] == 'GOAT_AND_FISH_FARMING_BUSINESS' &&
          decoded.containsKey('transactions') &&
          decoded.containsKey('investors')) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<int> mergeBackupData(Map<String, dynamic> data) async {
    final db = await database;
    int importedCount = 0;

    await db.transaction((txn) async {
      final incomingInvestors = (data['investors'] as List).cast<Map<String, dynamic>>();
      for (var inv in incomingInvestors) {
        final existing = await txn.query('investors', where: 'id = ?', whereArgs: [inv['id']]);
        if (existing.isEmpty) {
          await txn.insert('investors', inv);
        }
      }

      final incomingTx = (data['transactions'] as List).cast<Map<String, dynamic>>();
      for (var tx in incomingTx) {
        final existing = await txn.query('transactions', where: 'id = ?', whereArgs: [tx['id']]);
        if (existing.isEmpty) {
          await txn.insert('transactions', tx);
          importedCount++;
        }
      }
    });

    return importedCount;
  }

  Future<void> replaceAllData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('investors');
      await txn.delete('transactions');

      final incomingInvestors = (data['investors'] as List).cast<Map<String, dynamic>>();
      for (var inv in incomingInvestors) {
        await txn.insert('investors', inv);
      }

      final incomingTx = (data['transactions'] as List).cast<Map<String, dynamic>>();
      for (var tx in incomingTx) {
        await txn.insert('transactions', tx);
      }
    });
  }
}
