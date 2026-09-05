import 'package:spendly/domain/entities/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getBudgets(int month, int year);
  Future<void> saveBudget(Budget budget);
  Future<void> deleteBudget(String id);
}
