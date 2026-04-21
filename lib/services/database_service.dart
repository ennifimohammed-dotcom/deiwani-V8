import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/debt.dart';

class DatabaseService {
  static final DatabaseService _i = DatabaseService._();
  factory DatabaseService() => _i;
  DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'deiwani_v4.db');
    return openDatabase(path, version: 1, onCreate: (d, _) async {
      await d.execute('''
        CREATE TABLE debts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL,
          due_date TEXT,
          is_settled INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await d.execute('''
        CREATE TABLE payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          debt_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE CASCADE
        )
      ''');
    });
  }

  Future<List<Payment>> _getPayments(int debtId) async {
    final d = await db;
    final rows = await d.query('payments',
        where: 'debt_id = ?',
        whereArgs: [debtId],
        orderBy: 'date ASC');
    return rows
        .map((r) => Payment(
              amount: (r['amount'] as num).toDouble(),
              date: DateTime.parse(r['date'] as String),
              note: r['note'] as String?,
            ))
        .toList();
  }

  Future<int> insertDebt(Debt debt) async {
    final d = await db;
    final map = debt.toMap()..remove('id');
    return d.insert('debts', map);
  }

  Future<List<Debt>> getAllDebts() async {
    final d = await db;
    final rows = await d.query('debts', orderBy: 'created_at DESC');
    final List<Debt> result = [];
    for (final row in rows) {
      final id = row['id'] as int;
      final payments = await _getPayments(id);
      result.add(Debt.fromMap(row, payments));
    }
    return result;
  }

  Future<void> updateDebt(Debt debt) async {
    final d = await db;
    await d.update('debts', debt.toMap(),
        where: 'id = ?', whereArgs: [debt.id]);
  }

  Future<void> deleteDebt(int id) async {
    final d = await db;
    await d.delete('payments', where: 'debt_id = ?', whereArgs: [id]);
    await d.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final d = await db;
    await d.delete('payments');
    await d.delete('debts');
  }

  Future<void> addPayment(
      int debtId, double amount, DateTime date, String? note) async {
    final d = await db;
    await d.insert('payments', {
      'debt_id': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    });
  }
}
