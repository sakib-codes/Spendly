import 'package:equatable/equatable.dart';

enum CategoryType { expense, income, both }

class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final CategoryType type;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        type,
        sortOrder,
        createdAt,
        updatedAt,
        isSynced,
        deletedAt,
      ];
}
