import '../../core/database/database_tables.dart';
import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.type,
    required super.categoryId,
    required super.date,
    super.paymentMethod,
    super.note,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced = false,
    super.deletedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map[TransactionFields.id] as String,
      title: map[TransactionFields.title] as String,
      amount: map[TransactionFields.amount] as double,
      type: map[TransactionFields.type] == 'expense'
          ? TransactionType.expense
          : TransactionType.income,
      categoryId: map[TransactionFields.categoryId] as String,
      date: DateTime.fromMillisecondsSinceEpoch(
        map[TransactionFields.date] as int,
      ),
      paymentMethod: map[TransactionFields.paymentMethod] as String?,
      note: map[TransactionFields.note] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[TransactionFields.createdAt] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[TransactionFields.updatedAt] as int,
      ),
      isSynced: (map[TransactionFields.isSynced] as int?) == 1,
      deletedAt: map[TransactionFields.deletedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[TransactionFields.deletedAt] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      TransactionFields.id: id,
      TransactionFields.title: title,
      TransactionFields.amount: amount,
      TransactionFields.type: type == TransactionType.expense
          ? 'expense'
          : 'income',
      TransactionFields.categoryId: categoryId,
      TransactionFields.date: date.millisecondsSinceEpoch,
      TransactionFields.paymentMethod: paymentMethod,
      TransactionFields.note: note,
      TransactionFields.createdAt: createdAt.millisecondsSinceEpoch,
      TransactionFields.updatedAt: updatedAt.millisecondsSinceEpoch,
      TransactionFields.isSynced: isSynced ? 1 : 0,
      TransactionFields.deletedAt: deletedAt?.millisecondsSinceEpoch,
    };
  }
}
