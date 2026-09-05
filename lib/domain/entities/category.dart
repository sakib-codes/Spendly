import 'package:equatable/equatable.dart';

enum CategoryType { expense, income, both }

class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final CategoryType type;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, icon, type, createdAt];
}
