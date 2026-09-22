import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_tables.dart';
import 'package:spendly/data/models/transaction_model.dart';
import 'package:spendly/domain/entities/transaction.dart';

import 'transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  @override
  Future<List<Transaction>> getTransactions() async {
    final db = await AppDatabase.instance;
    final result = await db.query(
      DatabaseTables.transactions,
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
    );
    await db.insert(DatabaseTables.transactions, model.toMap());
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
    );
    await db.update(
      DatabaseTables.transactions,
      model.toMap(),
      where: '${TransactionFields.id} = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await AppDatabase.instance;
    await db.delete(
      DatabaseTables.transactions,
      where: '${TransactionFields.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAllTransactions() async {
    final db = await AppDatabase.instance;
    await db.delete(DatabaseTables.transactions);
  }
}
