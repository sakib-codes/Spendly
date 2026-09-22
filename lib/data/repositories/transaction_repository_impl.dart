import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_tables.dart';
import 'package:spendly/data/models/transaction_model.dart';
import 'package:spendly/domain/entities/transaction.dart';

import 'package:spendly/features/sync/services/sync_service.dart';

import 'transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  @override
  Future<List<Transaction>> getTransactions() async {
    final db = await AppDatabase.instance;
    final result = await db.query(
      DatabaseTables.transactions,
      where: '${TransactionFields.deletedAt} IS NULL',
      orderBy: '${TransactionFields.date} DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final db = await AppDatabase.instance;
    final result = await db.query(
      DatabaseTables.transactions,
      where: '${TransactionFields.id} = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return TransactionModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    final db = await AppDatabase.instance;
    final model = TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      date: transaction.date,
      paymentMethod: transaction.paymentMethod,
      note: transaction.note,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      isSynced: false,
    );
    await db.insert(DatabaseTables.transactions, model.toMap());
    SyncService().push();
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final db = await AppDatabase.instance;
    final model = TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      date: transaction.date,
      paymentMethod: transaction.paymentMethod,
      note: transaction.note,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      isSynced: false,
    );
    await db.update(
      DatabaseTables.transactions,
      model.toMap(),
      where: '${TransactionFields.id} = ?',
      whereArgs: [transaction.id],
    );
    SyncService().push();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await AppDatabase.instance;
    
    // Instead of actual delete, we mark it as deleted for offline sync
    // If it was never synced, we can hard delete it.
    final existing = await db.query(
      DatabaseTables.transactions,
      where: '${TransactionFields.id} = ?',
      whereArgs: [id],
    );
    
    if (existing.isNotEmpty && (existing.first[TransactionFields.isSynced] as int?) == 1) {
      await db.update(
        DatabaseTables.transactions,
        {
           TransactionFields.deletedAt: DateTime.now().millisecondsSinceEpoch,
           TransactionFields.isSynced: 0,
        },
        where: '${TransactionFields.id} = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete(
        DatabaseTables.transactions,
        where: '${TransactionFields.id} = ?',
        whereArgs: [id],
      );
    }
    SyncService().push();
  }

  @override
  Future<void> clearAllTransactions() async {
    final db = await AppDatabase.instance;
    await db.delete(DatabaseTables.transactions);
  }
}
