import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_tables.dart';
import 'package:spendly/data/models/category_model.dart';
import 'package:spendly/domain/entities/category.dart';

import 'package:spendly/features/sync/services/sync_service.dart';

import 'category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<List<Category>> getCategories() async {
    final db = await AppDatabase.instance;
    final result = await db.query(
      DatabaseTables.categories,
      where: '${CategoryFields.deletedAt} IS NULL',
      orderBy: '${CategoryFields.sortOrder} ASC',
    );
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final db = await AppDatabase.instance;
    final result = await db.query(
      DatabaseTables.categories,
      where: '${CategoryFields.id} = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return CategoryModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<void> addCategory(Category category) async {
    final db = await AppDatabase.instance;
    final model = CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      type: category.type,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
      isSynced: false,
    );
    await db.insert(DatabaseTables.categories, model.toMap());
    SyncService().push();
  }

  @override
  Future<void> updateCategory(Category category) async {
    final db = await AppDatabase.instance;
    final model = CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      type: category.type,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
      isSynced: false,
    );
    await db.update(
      DatabaseTables.categories,
      model.toMap(),
      where: '${CategoryFields.id} = ?',
      whereArgs: [category.id],
    );
    SyncService().push();
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await AppDatabase.instance;
    
    final existing = await db.query(
      DatabaseTables.categories,
      where: '${CategoryFields.id} = ?',
      whereArgs: [id],
    );
    
    if (existing.isNotEmpty && (existing.first[CategoryFields.isSynced] as int?) == 1) {
      await db.update(
        DatabaseTables.categories,
        {
           CategoryFields.deletedAt: DateTime.now().millisecondsSinceEpoch,
           CategoryFields.isSynced: 0,
        },
        where: '${CategoryFields.id} = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete(
        DatabaseTables.categories,
        where: '${CategoryFields.id} = ?',
        whereArgs: [id],
      );
    }
    SyncService().push();
  }

  @override
  Future<void> updateCategoriesOrder(List<Category> categories) async {
    final db = await AppDatabase.instance;
    final batch = db.batch();
    for (var category in categories) {
      batch.update(
        DatabaseTables.categories,
        {CategoryFields.sortOrder: category.sortOrder},
        where: '${CategoryFields.id} = ?',
        whereArgs: [category.id],
      );
    }
    await batch.commit(noResult: true);
  }
}
