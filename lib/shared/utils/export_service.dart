import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spendly/domain/entities/transaction.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  static Future<void> exportTransactionsToCSV(
    List<Transaction> transactions,
  ) async {
    final List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'ID',
      'Title',
      'Amount',
      'Type',
      'Category ID',
      'Date',
      'Payment Method',
      'Note',
      'Created At',
    ]);

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
    final path =
        '${directory.path}/spendly_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);

    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Spendly Transactions Export'),
    );
  }

  static Future<void> exportTransactionsToPDF(
    List<Transaction> transactions,
    List<Category> categories,
    String currencyPref,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    String getPdfSafeCurrency(String symbol) {
      if (symbol == '৳') return 'Tk ';
      if (symbol == '₹') return 'Rs ';
      return symbol;
    }
    
    final pdfCurrency = getPdfSafeCurrency(currencyPref);

    final categoryMap = {for (var c in categories) c.id: c.name};

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in transactions) {
      if (t.type.name == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    double netBalance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Spendly Export', style: pw.TextStyle(font: boldFont, fontSize: 24)),
                  pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: pw.TextStyle(font: font)),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Title', 'Category', 'Type', 'Amount'],
              data: transactions.map((t) {
                return [
                  dateFormat.format(t.date),
                  t.title,
                  categoryMap[t.categoryId] ?? 'Unknown',
                  t.type.name.toUpperCase(),
                  '$pdfCurrency${t.amount.toStringAsFixed(2)}',
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
              cellStyle: pw.TextStyle(font: font),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellHeight: 30,
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(2),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Income: $pdfCurrency${totalIncome.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, color: PdfColors.green700)),
                pw.Text('Total Expenses: $pdfCurrency${totalExpense.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, color: PdfColors.red700)),
              ]
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Net Balance: $pdfCurrency${netBalance.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, fontSize: 16)),
              ]
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/spendly_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);

    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Spendly Transactions PDF Export'),
    );
  }
}
