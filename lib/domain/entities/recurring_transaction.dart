import 'package:equatable/equatable.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class RecurringTransaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String type; // 'expense' or 'income'
  final String categoryId;
  final RecurrenceFrequency frequency;
  final DateTime nextDate;
  final DateTime? endDate;
  final String? paymentMethod;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? deletedAt;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.frequency,
    required this.nextDate,
    this.endDate,
    this.paymentMethod,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.deletedAt,
  });

  RecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? categoryId,
    RecurrenceFrequency? frequency,
    DateTime? nextDate,
    DateTime? endDate,
    String? paymentMethod,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      endDate: endDate ?? this.endDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        type,
        categoryId,
        frequency,
        nextDate,
        endDate,
        paymentMethod,
        note,
        createdAt,
        updatedAt,
        isSynced,
        deletedAt,
      ];
}
