import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/recurring_transaction_repository_impl.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_provider.dart';

final recurringTransactionRepositoryProvider = Provider((ref) {
  return RecurringTransactionRepositoryImpl();
});

class RecurringTransactionNotifier extends AsyncNotifier<List<RecurringTransaction>> {
  @override
  FutureOr<List<RecurringTransaction>> build() async {
    final repository = ref.read(recurringTransactionRepositoryProvider);
    return repository.getRecurringTransactions();
  }

  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(recurringTransactionRepositoryProvider);
      await repository.saveRecurringTransaction(transaction);
      return repository.getRecurringTransactions();
    });
  }

  Future<void> updateRecurringTransaction(RecurringTransaction transaction) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(recurringTransactionRepositoryProvider);
      final updated = transaction.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await repository.saveRecurringTransaction(updated);
      return repository.getRecurringTransactions();
    });
  }

  Future<void> deleteRecurringTransaction(String id) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(recurringTransactionRepositoryProvider);
      await repository.deleteRecurringTransaction(id);
      return repository.getRecurringTransactions();
    });
  }

  Future<void> processPending() async {
    try {
      final repository = ref.read(recurringTransactionRepositoryProvider);
      final pending = await repository.getPendingRecurringTransactions();
      if (pending.isEmpty) return;

      for (var recurring in pending) {
        var currentNextDate = recurring.nextDate;

        // Loop while the next date is in the past (to catch up on missed periods)
        while (!currentNextDate.isAfter(DateTime.now())) {
          // Generate a new transaction
          final newTransaction = Transaction(
            id: const Uuid().v4(),
            title: recurring.title,
            amount: recurring.amount,
            type: recurring.type == 'expense'
                ? TransactionType.expense
                : TransactionType.income,
            categoryId: recurring.categoryId,
            date: currentNextDate,
            paymentMethod: recurring.paymentMethod,
            note: recurring.note,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await ref.read(transactionProvider.notifier).addTransaction(newTransaction);

          // Calculate next date
          currentNextDate = _calculateNextDate(currentNextDate, recurring.frequency);

          // Check if we passed the end date
          if (recurring.endDate != null && currentNextDate.isAfter(recurring.endDate!)) {
            await repository.deleteRecurringTransaction(recurring.id);
            break;
          }
        }

        // Save the updated nextDate for this recurring transaction
        final updated = recurring.copyWith(
          nextDate: currentNextDate,
          updatedAt: DateTime.now(),
          isSynced: false,
        );
        await repository.saveRecurringTransaction(updated);
      }

      // Reload the state
      state = AsyncValue.data(await repository.getRecurringTransactions());
    } catch (e) {
      // Silently handle — don't crash the app on startup
    }
  }

  DateTime _calculateNextDate(DateTime current, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return current.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return current.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        int year = current.year;
        int month = current.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        int day = current.day;
        final daysInNextMonth = DateTime(year, month + 1, 0).day;
        if (day > daysInNextMonth) day = daysInNextMonth;
        return DateTime(year, month, day, current.hour, current.minute);
      case RecurrenceFrequency.yearly:
        return DateTime(
            current.year + 1, current.month, current.day, current.hour, current.minute);
    }
  }
}

final recurringTransactionProvider =
    AsyncNotifierProvider<RecurringTransactionNotifier, List<RecurringTransaction>>(() {
      return RecurringTransactionNotifier();
    });
