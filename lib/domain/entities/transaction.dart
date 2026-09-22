import 'package:equatable/equatable.dart';

enum TransactionType { expense, income }

class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String? paymentMethod;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.paymentMethod,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    type,
    categoryId,
    date,
    paymentMethod,
    note,
    createdAt,
    updatedAt,
  ];
}
