import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import 'transaction_provider.dart';
import 'category_provider.dart';

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime newMonth) {
    state = newMonth;
  }
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  () {
    return SelectedMonthNotifier();
  },
);

class DashboardStats {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;

  DashboardStats({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final transactionsState = ref.watch(transactionProvider);

  return transactionsState.maybeWhen(
    data: (transactions) {
      double income = 0;
      double expense = 0;
      final selectedMonth = ref.watch(selectedMonthProvider);

      for (var t in transactions) {
        if (t.date.month == selectedMonth.month &&
            t.date.year == selectedMonth.year) {
          if (t.type == TransactionType.income) {
            income += t.amount;
          } else {
            expense += t.amount;
          }
        }
      }

      return DashboardStats(
        totalBalance: income - expense,
        totalIncome: income,
        totalExpense: expense,
      );
    },
    orElse: () =>
        DashboardStats(totalBalance: 0, totalIncome: 0, totalExpense: 0),
  );
});

class CategorySpending {
  final String categoryName;
  final double amount;
  final double percentage;
  final Color color;

  CategorySpending(this.categoryName, this.amount, this.percentage, this.color);
}

final spendingBreakdownProvider = Provider<List<CategorySpending>>((ref) {
  final transactionsState = ref.watch(transactionProvider);
  final categoriesState = ref.watch(categoryProvider);

  return transactionsState.maybeWhen(
    data: (transactions) {
      return categoriesState.maybeWhen(
        data: (categories) {
          final selectedMonth = ref.watch(selectedMonthProvider);
          final expenseTransactions = transactions
              .where(
                (t) =>
                    t.type == TransactionType.expense &&
                    t.date.month == selectedMonth.month &&
                    t.date.year == selectedMonth.year,
              )
              .toList();
          if (expenseTransactions.isEmpty) return [];

          double totalExpense = expenseTransactions.fold(
            0,
            (sum, t) => sum + t.amount,
          );

          Map<String, double> categorySums = {};
          for (var t in expenseTransactions) {
            categorySums[t.categoryId] =
                (categorySums[t.categoryId] ?? 0) + t.amount;
          }

          final List<Color> colors = [
            const Color(0xFFEF5350), // Red
            const Color(0xFF42A5F5), // Blue
            const Color(0xFFFFA726), // Orange
            const Color(0xFF66BB6A), // Green
            const Color(0xFFAB47BC), // Purple
            const Color(0xFF26C6DA), // Teal
          ];

          List<CategorySpending> breakdown = [];
          int colorIndex = 0;

          categorySums.forEach((categoryId, amount) {
            final category = categories.cast<Category>().firstWhere(
              (c) => c.id == categoryId,
              orElse: () => Category(
                id: '',
                name: 'Unknown',
                icon: '',
                type: CategoryType.expense,
                createdAt: DateTime.now(),
              ),
            );

            breakdown.add(
              CategorySpending(
                category.name,
                amount,
                (amount / totalExpense) * 100,
                colors[colorIndex % colors.length],
              ),
            );
            colorIndex++;
          });

          breakdown.sort((a, b) => b.amount.compareTo(a.amount));
          return breakdown;
        },
        orElse: () => [],
      );
    },
    orElse: () => [],
  );
});

class SpendingTrend {
  final List<double> dailyExpense;
  final List<double> dailyIncome;
  final double avgExpensePerDay;
  final double avgIncomePerDay;

  SpendingTrend({
    required this.dailyExpense,
    required this.dailyIncome,
    required this.avgExpensePerDay,
    required this.avgIncomePerDay,
  });
}

final spendingTrendProvider = Provider<SpendingTrend>((ref) {
  final transactionsState = ref.watch(transactionProvider);

  return transactionsState.maybeWhen(
    data: (transactions) {
      final selectedMonth = ref.watch(selectedMonthProvider);

      // Calculate for the entire selected month
      final daysInMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        0,
      ).day;
      List<double> expenseTotals = List.filled(daysInMonth, 0.0);
      List<double> incomeTotals = List.filled(daysInMonth, 0.0);

      double totalExpense = 0;
      double totalIncome = 0;

      for (var t in transactions) {
        if (t.date.year == selectedMonth.year &&
            t.date.month == selectedMonth.month) {
          int dayIndex = t.date.day - 1; // 0-indexed
          if (dayIndex >= 0 && dayIndex < daysInMonth) {
            if (t.type == TransactionType.expense) {
              totalExpense += t.amount;
              expenseTotals[dayIndex] += t.amount;
            } else if (t.type == TransactionType.income) {
              totalIncome += t.amount;
              incomeTotals[dayIndex] += t.amount;
            }
          }
        }
      }

      final now = DateTime.now();
      int daysToDivide = daysInMonth;
      if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
        daysToDivide = now.day;
      }

      return SpendingTrend(
        dailyExpense: expenseTotals,
        dailyIncome: incomeTotals,
        avgExpensePerDay: totalExpense > 0 ? totalExpense / daysToDivide : 0,
        avgIncomePerDay: totalIncome > 0 ? totalIncome / daysToDivide : 0,
      );
    },
    orElse: () => SpendingTrend(
      dailyExpense: List.filled(7, 0.0),
      dailyIncome: List.filled(7, 0.0),
      avgExpensePerDay: 0,
      avgIncomePerDay: 0,
    ),
  );
});

class MonthComparison {
  final double currentMonthExpense;
  final double lastMonthExpense;
  final String lastMonthName;

  double get difference => lastMonthExpense > 0
      ? ((currentMonthExpense - lastMonthExpense) / lastMonthExpense * 100)
      : 0;
  bool get isLower => currentMonthExpense < lastMonthExpense;

  MonthComparison({
    required this.currentMonthExpense,
    required this.lastMonthExpense,
    required this.lastMonthName,
  });
}

final monthComparisonProvider = Provider<MonthComparison>((ref) {
  final transactionsState = ref.watch(transactionProvider);

  return transactionsState.maybeWhen(
    data: (transactions) {
      final selectedMonth = ref.watch(selectedMonthProvider);
      final lastMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);

      double currentExpense = 0;
      double lastExpense = 0;

      for (var t in transactions) {
        if (t.type == TransactionType.expense) {
          if (t.date.month == selectedMonth.month &&
              t.date.year == selectedMonth.year) {
            currentExpense += t.amount;
          } else if (t.date.month == lastMonth.month &&
              t.date.year == lastMonth.year) {
            lastExpense += t.amount;
          }
        }
      }

      return MonthComparison(
        currentMonthExpense: currentExpense,
        lastMonthExpense: lastExpense,
        lastMonthName: _monthName(lastMonth.month),
      );
    },
    orElse: () => MonthComparison(
      currentMonthExpense: 0,
      lastMonthExpense: 0,
      lastMonthName: '',
    ),
  );
});

String _monthName(int month) {
  const names = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[month.clamp(1, 12)];
}
