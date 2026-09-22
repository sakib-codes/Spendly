import '../../core/database/database_tables.dart';
import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.type,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced = false,
    super.deletedAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    CategoryType parseType(String val) {
      if (val == 'expense') return CategoryType.expense;
      if (val == 'income') return CategoryType.income;
      return CategoryType.both;
    }

    return CategoryModel(
      id: map[CategoryFields.id] as String,
      name: map[CategoryFields.name] as String,
      icon: map[CategoryFields.icon] as String,
      type: parseType(map[CategoryFields.type] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[CategoryFields.createdAt] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[CategoryFields.updatedAt] as int? ?? map[CategoryFields.createdAt] as int,
      ),
      isSynced: (map[CategoryFields.isSynced] as int?) == 1,
      deletedAt: map[CategoryFields.deletedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[CategoryFields.deletedAt] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    String typeStr = 'both';
    if (type == CategoryType.expense) typeStr = 'expense';
    if (type == CategoryType.income) typeStr = 'income';

    return {
      CategoryFields.id: id,
      CategoryFields.name: name,
      CategoryFields.icon: icon,
      CategoryFields.type: typeStr,
      CategoryFields.createdAt: createdAt.millisecondsSinceEpoch,
      CategoryFields.updatedAt: updatedAt.millisecondsSinceEpoch,
      CategoryFields.isSynced: isSynced ? 1 : 0,
      CategoryFields.deletedAt: deletedAt?.millisecondsSinceEpoch,
    };
  }
}
