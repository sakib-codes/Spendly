import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final String id;
  final String categoryId;
  final double amount;
  final int month;
  final int year;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? deletedAt;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    required this.updatedAt,
    this.isSynced = false,
    this.deletedAt,
  });

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    int? month,
    int? year,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        amount,
        month,
        year,
        updatedAt,
        isSynced,
        deletedAt,
      ];
}
