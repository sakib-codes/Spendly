import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spendly/domain/entities/transaction.dart';

class ExportService {
  static Future<void> exportTransactionsToCSV(List<Transaction> transactions) async {
    final List<List<dynamic>> rows = [];
    
    // Header
    rows.add(['ID', 'Title', 'Amount', 'Type', 'Category ID', 'Date', 'Payment Method', 'Note', 'Created At']);
    
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    
    for (var t in transactions) {
      rows.add([
        t.id,
        t.title,
        t.amount,
        t.type.name,
        t.categoryId,
        dateFormat.format(t.date),
        t.paymentMethod ?? '',
        t.note ?? '',
        dateFormat.format(t.createdAt),
      ]);
    }

    String csv = rows.map((row) => row.join(',')).join('\n');

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/spendly_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    
    await file.writeAsString(csv);
    
    await Share.shareXFiles([XFile(path)], text: 'Spendly Transactions Export');
  }
}
