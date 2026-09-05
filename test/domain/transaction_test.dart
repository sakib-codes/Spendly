import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/domain/entities/transaction.dart';

void main() {
  group('Transaction Entity Tests', () {
    test('should instantiate correctly', () {
      final t = Transaction(
        id: '1',
        title: 'Test',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'cat1',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(t.title, 'Test');
    });
  });
}
