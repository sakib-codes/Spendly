import 'package:spendly/core/database/app_database.dart';
import 'package:spendly/core/database/database_tables.dart';
import 'package:spendly/data/models/category_model.dart';
import 'package:spendly/domain/entities/category.dart';
import 'category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<List<Category>> getCategories() async {
    final db = await AppDatabase.instance;
    final result = await db.query(DatabaseTables.categories);
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
    );
    await db.insert(DatabaseTables.categories, model.toMap());
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
    );
    await db.update(
      DatabaseTables.categories,
      model.toMap(),
      where: '${CategoryFields.id} = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await AppDatabase.instance;
    await db.delete(
      DatabaseTables.categories,
      where: '${CategoryFields.id} = ?',
      whereArgs: [id],
    );
  }
}
