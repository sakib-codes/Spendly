import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../../domain/entities/recurring_transaction.dart';
import 'recurring_transaction_repository.dart';

class RecurringTransactionRepositoryImpl implements RecurringTransactionRepository {
  Future<Database> get _db async => await AppDatabase.instance;

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final db = await _db;
    final maps = await db.query(
      DatabaseTables.recurringTransactions,
      where: '${RecurringTransactionFields.deletedAt} IS NULL',
      orderBy: '${RecurringTransactionFields.nextDate} ASC',
    );
    return maps.map((e) => _fromMap(e)).toList();
  }

  @override
  Future<RecurringTransaction?> getRecurringTransaction(String id) async {
    final db = await _db;
    final maps = await db.query(
      DatabaseTables.recurringTransactions,
      where: '${RecurringTransactionFields.id} = ? AND ${RecurringTransactionFields.deletedAt} IS NULL',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  @override
  Future<void> saveRecurringTransaction(RecurringTransaction recurringTransaction) async {
    final db = await _db;
    await db.insert(
      DatabaseTables.recurringTransactions,
      _toMap(recurringTransaction),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      DatabaseTables.recurringTransactions,
      {
        RecurringTransactionFields.deletedAt: now,
        RecurringTransactionFields.updatedAt: now,
        RecurringTransactionFields.isSynced: 0,
      },
      where: '${RecurringTransactionFields.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<RecurringTransaction>> getPendingRecurringTransactions() async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      DatabaseTables.recurringTransactions,
      where: '${RecurringTransactionFields.deletedAt} IS NULL AND ${RecurringTransactionFields.nextDate} <= ?',
      whereArgs: [now],
    );
    return maps.map((e) => _fromMap(e)).toList();
  }

  Map<String, dynamic> _toMap(RecurringTransaction rt) {
    return {
      RecurringTransactionFields.id: rt.id,
      RecurringTransactionFields.title: rt.title,
      RecurringTransactionFields.amount: rt.amount,
      RecurringTransactionFields.type: rt.type,
      RecurringTransactionFields.categoryId: rt.categoryId,
      RecurringTransactionFields.frequency: rt.frequency.name,
      RecurringTransactionFields.nextDate: rt.nextDate.millisecondsSinceEpoch,
      RecurringTransactionFields.endDate: rt.endDate?.millisecondsSinceEpoch,
      RecurringTransactionFields.paymentMethod: rt.paymentMethod,
      RecurringTransactionFields.note: rt.note,
      RecurringTransactionFields.createdAt: rt.createdAt.millisecondsSinceEpoch,
      RecurringTransactionFields.updatedAt: rt.updatedAt.millisecondsSinceEpoch,
      RecurringTransactionFields.isSynced: rt.isSynced ? 1 : 0,
      RecurringTransactionFields.deletedAt: rt.deletedAt?.millisecondsSinceEpoch,
    };
  }

  RecurringTransaction _fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map[RecurringTransactionFields.id] as String,
      title: map[RecurringTransactionFields.title] as String,
      amount: map[RecurringTransactionFields.amount] as double,
      type: map[RecurringTransactionFields.type] as String,
      categoryId: map[RecurringTransactionFields.categoryId] as String,
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == map[RecurringTransactionFields.frequency],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      nextDate: DateTime.fromMillisecondsSinceEpoch(map[RecurringTransactionFields.nextDate] as int),
      endDate: map[RecurringTransactionFields.endDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(map[RecurringTransactionFields.endDate] as int)
          : null,
      paymentMethod: map[RecurringTransactionFields.paymentMethod] as String?,
      note: map[RecurringTransactionFields.note] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[RecurringTransactionFields.createdAt] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[RecurringTransactionFields.updatedAt] as int),
      isSynced: (map[RecurringTransactionFields.isSynced] as int) == 1,
      deletedAt: map[RecurringTransactionFields.deletedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(map[RecurringTransactionFields.deletedAt] as int)
          : null,
    );
  }
}
