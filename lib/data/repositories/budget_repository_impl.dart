import 'package:sqflite/sqflite.dart';
import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_tables.dart';
import 'package:spendly/domain/entities/budget.dart';

import 'package:spendly/features/sync/services/sync_service.dart';

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
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            maps[i][BudgetFields.updatedAt] as int? ?? DateTime.now().millisecondsSinceEpoch),
        isSynced: (maps[i][BudgetFields.isSynced] as int?) == 1,
        deletedAt: maps[i][BudgetFields.deletedAt] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                maps[i][BudgetFields.deletedAt] as int)
            : null,
      );
    });
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    final db = await AppDatabase.instance;

    // Check if budget already exists for this category/month/year
    final List<Map<String, dynamic>> existing = await db.query(
      DatabaseTables.budgets,
      where:
          '${BudgetFields.categoryId} = ? AND ${BudgetFields.month} = ? AND ${BudgetFields.year} = ?',
      whereArgs: [budget.categoryId, budget.month, budget.year],
    );

    if (existing.isNotEmpty) {
      // Update
      final existingId = existing.first[BudgetFields.id];
      await db.update(
        DatabaseTables.budgets,
        {
          BudgetFields.amount: budget.amount,
          BudgetFields.updatedAt: budget.updatedAt.millisecondsSinceEpoch,
          BudgetFields.isSynced: 0,
          BudgetFields.deletedAt: budget.deletedAt?.millisecondsSinceEpoch,
        },
        where: '${BudgetFields.id} = ?',
        whereArgs: [existingId],
      );
    } else {
      // Insert
      await db.insert(DatabaseTables.budgets, {
        BudgetFields.id: budget.id,
        BudgetFields.categoryId: budget.categoryId,
        BudgetFields.amount: budget.amount,
        BudgetFields.month: budget.month,
        BudgetFields.year: budget.year,
        BudgetFields.updatedAt: budget.updatedAt.millisecondsSinceEpoch,
        BudgetFields.isSynced: 0,
        BudgetFields.deletedAt: budget.deletedAt?.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    SyncService().push();
  }

  @override
  Future<void> deleteBudget(String id) async {
    final db = await AppDatabase.instance;
    
    final existing = await db.query(
      DatabaseTables.budgets,
      where: '${BudgetFields.id} = ?',
      whereArgs: [id],
    );
    
    if (existing.isNotEmpty && (existing.first[BudgetFields.isSynced] as int?) == 1) {
      await db.update(
        DatabaseTables.budgets,
        {
           BudgetFields.deletedAt: DateTime.now().millisecondsSinceEpoch,
           BudgetFields.isSynced: 0,
        },
        where: '${BudgetFields.id} = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete(
        DatabaseTables.budgets,
        where: '${BudgetFields.id} = ?',
        whereArgs: [id],
      );
    }
    SyncService().push();
  }
}
