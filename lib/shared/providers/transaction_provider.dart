import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction.dart';
import 'repository_providers.dart';

import 'dart:async';

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  FutureOr<List<Transaction>> build() async {
    final repository = ref.read(transactionRepositoryProvider);
    return repository.getTransactions();
  }

  Future<void> addTransaction(Transaction transaction) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.addTransaction(transaction);
      return repository.getTransactions();
    });
  }

  Future<void> deleteTransaction(String id) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.deleteTransaction(id);
      return repository.getTransactions();
    });
  }

  Future<void> updateTransaction(Transaction transaction) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.updateTransaction(transaction);
      return repository.getTransactions();
    });
  }

  Future<void> clearAll() async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.clearAllTransactions();
      return [];
    });
  }
}

final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(() {
      return TransactionNotifier();
    });

class TransactionFilterNotifier extends Notifier<TransactionType?> {
  @override
  TransactionType? build() => null;

  void setFilter(TransactionType? filter) {
    state = filter;
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionType?>(() {
      return TransactionFilterNotifier();
    });
