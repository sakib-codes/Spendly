import '../../domain/entities/recurring_transaction.dart';

abstract class RecurringTransactionRepository {
  Future<List<RecurringTransaction>> getRecurringTransactions();
  Future<RecurringTransaction?> getRecurringTransaction(String id);
  Future<void> saveRecurringTransaction(RecurringTransaction recurringTransaction);
  Future<void> deleteRecurringTransaction(String id);
  Future<List<RecurringTransaction>> getPendingRecurringTransactions();
}
