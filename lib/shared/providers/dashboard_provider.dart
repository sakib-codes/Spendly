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
                updatedAt: DateTime.now(),
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
  final String currentMonthName;
  final String lastMonthName;

  double get difference => lastMonthExpense > 0
      ? ((currentMonthExpense - lastMonthExpense) / lastMonthExpense * 100)
      : 0;
  bool get isLower => currentMonthExpense < lastMonthExpense;

  MonthComparison({
    required this.currentMonthExpense,
    required this.lastMonthExpense,
    required this.currentMonthName,
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
        currentMonthName: _monthName(selectedMonth.month),
        lastMonthName: _monthName(lastMonth.month),
      );
    },
    orElse: () => MonthComparison(
      currentMonthExpense: 0,
      lastMonthExpense: 0,
      currentMonthName: '',
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

class MonthSummary {
  final String monthName;
  final double income;
  final double expense;

  MonthSummary(this.monthName, this.income, this.expense);
}

final sixMonthTrendProvider = Provider<List<MonthSummary>>((ref) {
  final transactionsState = ref.watch(transactionProvider);

  return transactionsState.maybeWhen(
    data: (transactions) {
      final now = DateTime.now();
      List<MonthSummary> summaries = [];

      for (int i = 5; i >= 0; i--) {
        final targetMonth = DateTime(now.year, now.month - i);
        double income = 0;
        double expense = 0;

        for (var t in transactions) {
          if (t.date.year == targetMonth.year &&
              t.date.month == targetMonth.month) {
            if (t.type == TransactionType.income) {
              income += t.amount;
            } else {
              expense += t.amount;
            }
          }
        }

        summaries.add(MonthSummary(
            _monthName(targetMonth.month).substring(0, 3), income, expense));
      }

      return summaries;
    },
    orElse: () => [],
  );
});

final topExpensesProvider = Provider<List<Transaction>>((ref) {
  final transactionsState = ref.watch(transactionProvider);

  return transactionsState.maybeWhen(
    data: (transactions) {
      final selectedMonth = ref.watch(selectedMonthProvider);
      final expenses = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.month == selectedMonth.month &&
              t.date.year == selectedMonth.year)
          .toList();

      expenses.sort((a, b) => b.amount.compareTo(a.amount));
      return expenses.take(5).toList();
    },
    orElse: () => [],
  );
});

class PaymentMethodSpending {
  final String methodName;
  final double amount;
  final double percentage;
  final Color color;

  PaymentMethodSpending(this.methodName, this.amount, this.percentage, this.color);
}

final paymentMethodBreakdownProvider =
    Provider<List<PaymentMethodSpending>>((ref) {
  final transactionsState = ref.watch(transactionProvider);

  return transactionsState.maybeWhen(
    data: (transactions) {
      final selectedMonth = ref.watch(selectedMonthProvider);
      final expenseTransactions = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.month == selectedMonth.month &&
              t.date.year == selectedMonth.year)
          .toList();

      if (expenseTransactions.isEmpty) return [];

      double totalExpense =
          expenseTransactions.fold(0, (sum, t) => sum + t.amount);

      Map<String, double> methodSums = {};
      for (var t in expenseTransactions) {
        final method = t.paymentMethod == null || t.paymentMethod!.isEmpty
            ? 'Other'
            : t.paymentMethod!;
        methodSums[method] = (methodSums[method] ?? 0) + t.amount;
      }

      final List<Color> colors = [
        const Color(0xFF5C6BC0), // Indigo
        const Color(0xFF26A69A), // Teal
        const Color(0xFFFFCA28), // Amber
        const Color(0xFFEC407A), // Pink
        const Color(0xFF8D6E63), // Brown
      ];

      List<PaymentMethodSpending> breakdown = [];
      int colorIndex = 0;

      methodSums.forEach((method, amount) {
        breakdown.add(PaymentMethodSpending(
          method,
          amount,
          (amount / totalExpense) * 100,
          colors[colorIndex % colors.length],
        ));
        colorIndex++;
      });

      breakdown.sort((a, b) => b.amount.compareTo(a.amount));
      return breakdown;
    },
    orElse: () => [],
  );
});
