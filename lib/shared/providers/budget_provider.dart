import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'dart:async';

import 'package:spendly/domain/entities/budget.dart';
import 'package:spendly/data/repositories/budget_repository.dart';
import 'package:spendly/data/repositories/budget_repository_impl.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/category_provider.dart';
import 'package:spendly/shared/providers/dashboard_provider.dart';
import 'package:spendly/domain/entities/category.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl();
});

class BudgetNotifier extends AsyncNotifier<List<Budget>> {
  @override
  FutureOr<List<Budget>> build() async {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final repository = ref.read(budgetRepositoryProvider);
    return repository.getBudgets(selectedMonth.month, selectedMonth.year);
  }

  Future<void> setBudget(String categoryId, double amount) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(budgetRepositoryProvider);
      final selectedMonth = ref.read(selectedMonthProvider);
      final budget = Budget(
        id: const Uuid().v4(),
        categoryId: categoryId,
        amount: amount,
        month: selectedMonth.month,
        year: selectedMonth.year,
        updatedAt: DateTime.now(),
      );

      await repository.saveBudget(budget);
      return repository.getBudgets(selectedMonth.month, selectedMonth.year);
    });
  }

  Future<void> removeBudget(String categoryId) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(budgetRepositoryProvider);
      final selectedMonth = ref.read(selectedMonthProvider);

      final currentBudgets = state.value ?? [];
      final targetBudget = currentBudgets
          .where((b) => b.categoryId == categoryId)
          .firstOrNull;

      if (targetBudget != null) {
        await repository.deleteBudget(targetBudget.id);
      }

      return repository.getBudgets(selectedMonth.month, selectedMonth.year);
    });
  }
}

final budgetProvider = AsyncNotifierProvider<BudgetNotifier, List<Budget>>(() {
  return BudgetNotifier();
});

class CategoryBudgetProgress {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final double budgetedAmount;
  final double spentAmount;

  double get percentage =>
      budgetedAmount > 0 ? (spentAmount / budgetedAmount).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => spentAmount > budgetedAmount;

  CategoryBudgetProgress({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.budgetedAmount,
    required this.spentAmount,
  });
}

final budgetProgressProvider =
    Provider<AsyncValue<List<CategoryBudgetProgress>>>((ref) {
      final categoriesState = ref.watch(categoryProvider);
      final budgetsState = ref.watch(budgetProvider);
      final transactionsState = ref.watch(transactionProvider);

      if (categoriesState is AsyncLoading ||
          budgetsState is AsyncLoading ||
          transactionsState is AsyncLoading) {
        return const AsyncValue.loading();
      }

      if (categoriesState is AsyncError) {
        return AsyncValue.error(
          categoriesState.error!,
          categoriesState.stackTrace!,
        );
      }
      if (budgetsState is AsyncError) {
        return AsyncValue.error(budgetsState.error!, budgetsState.stackTrace!);
      }
      if (transactionsState is AsyncError) {
        return AsyncValue.error(
          transactionsState.error!,
          transactionsState.stackTrace!,
        );
      }

      final categories = categoriesState.value ?? [];
      final budgets = budgetsState.value ?? [];
      final transactions = transactionsState.value ?? [];

      final selectedMonth = ref.watch(selectedMonthProvider);

      // Calculate spending per category for current month
      final Map<String, double> spendingPerCategory = {};
      for (var t in transactions) {
        if (t.date.month == selectedMonth.month &&
            t.date.year == selectedMonth.year &&
            t.type.name == 'expense') {
          spendingPerCategory[t.categoryId] =
              (spendingPerCategory[t.categoryId] ?? 0) + t.amount;
        }
      }

      // Build progress list
      final expenseCategories = categories
          .where(
            (c) =>
                c.type == CategoryType.expense || c.type == CategoryType.both,
          )
          .toList();

      final List<CategoryBudgetProgress> progressList = expenseCategories.map((
        cat,
      ) {
        final budget = budgets.where((b) => b.categoryId == cat.id).firstOrNull;
        final spent = spendingPerCategory[cat.id] ?? 0.0;

        return CategoryBudgetProgress(
          categoryId: cat.id,
          categoryName: cat.name,
          categoryIcon: cat.icon,
          budgetedAmount: budget?.amount ?? 0.0,
          spentAmount: spent,
        );
      }).toList();

      // Sort: ones with budgets first, then alphabetically
      progressList.sort((a, b) {
        if (a.budgetedAmount > 0 && b.budgetedAmount == 0) return -1;
        if (a.budgetedAmount == 0 && b.budgetedAmount > 0) return 1;
        return a.categoryName.compareTo(b.categoryName);
      });

      return AsyncValue.data(progressList);
    });
