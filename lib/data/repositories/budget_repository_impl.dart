import 'package:sqflite/sqflite.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_tables.dart';
import 'package:spendly/domain/entities/budget.dart';
import 'budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  @override
  Future<List<Budget>> getBudgets(int month, int year) async {
    final db = await AppDatabase.instance;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.budgets,
      where: '${BudgetFields.month} = ? AND ${BudgetFields.year} = ?',
      whereArgs: [month, year],
    );

    return List.generate(maps.length, (i) {
      return Budget(
        id: maps[i][BudgetFields.id],
        categoryId: maps[i][BudgetFields.categoryId],
        amount: maps[i][BudgetFields.amount],
        month: maps[i][BudgetFields.month],
        year: maps[i][BudgetFields.year],
      );
    });
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    final db = await AppDatabase.instance;
    
    // Check if budget already exists for this category/month/year
    final List<Map<String, dynamic>> existing = await db.query(
      DatabaseTables.budgets,
      where: '${BudgetFields.categoryId} = ? AND ${BudgetFields.month} = ? AND ${BudgetFields.year} = ?',
      whereArgs: [budget.categoryId, budget.month, budget.year],
    );
    
    if (existing.isNotEmpty) {
      // Update
      final existingId = existing.first[BudgetFields.id];
      await db.update(
        DatabaseTables.budgets,
        {
          BudgetFields.amount: budget.amount,
        },
        where: '${BudgetFields.id} = ?',
        whereArgs: [existingId],
      );
    } else {
      // Insert
      await db.insert(
        DatabaseTables.budgets,
        {
          BudgetFields.id: budget.id,
          BudgetFields.categoryId: budget.categoryId,
          BudgetFields.amount: budget.amount,
          BudgetFields.month: budget.month,
          BudgetFields.year: budget.year,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    final db = await AppDatabase.instance;
    await db.delete(
      DatabaseTables.budgets,
      where: '${BudgetFields.id} = ?',
      whereArgs: [id],
    );
  }
}
