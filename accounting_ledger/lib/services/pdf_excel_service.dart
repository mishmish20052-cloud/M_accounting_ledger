// lib/services/pdf_excel_service.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../utils/helpers.dart';

class PdfExcelService {
  // ─── PDF ──────────────────────────────────────────────────────────────────

  static Future<String> generateTransactionsPdf({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required String title,
    DateTime? from,
    DateTime? to,
  }) async {
    final pdf = pw.Document();

    final accountMap = {for (final a in accounts) a.id: a};

    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in transactions) {
      if (t.type == 'income') totalIncome += t.amount;
      if (t.type == 'expense') totalExpense += t.amount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (from != null && to != null)
            pw.Paragraph(
              text:
                  'Period: ${Helpers.formatDate(from)} - ${Helpers.formatDate(to)}',
            ),
          pw.SizedBox(height: 16),
          // Summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryBox('Total Income', totalIncome, PdfColors.green),
              _buildSummaryBox('Total Expense', totalExpense, PdfColors.red),
              _buildSummaryBox(
                  'Net', totalIncome - totalExpense, PdfColors.blue),
            ],
          ),
          pw.SizedBox(height: 24),
          // Transactions table
          pw.TableHelper.fromTextArray(
            headers: [
              'Date',
              'Type',
              'Category',
              'Account',
              'Amount',
              'Description'
            ],
            data: transactions.map((t) {
              final account = accountMap[t.accountId];
              return [
                Helpers.formatDate(t.date),
                t.type.toUpperCase(),
                t.category,
                account?.name ?? t.accountId,
                '${t.currency} ${t.amount.toStringAsFixed(2)}',
                t.description ?? '',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            rowDecoration: const pw.BoxDecoration(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/report_$timestamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  static pw.Widget _buildSummaryBox(
      String label, double amount, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: color, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(
            amount.toStringAsFixed(2),
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ─── Excel ────────────────────────────────────────────────────────────────

  static Future<String> generateTransactionsExcel({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required String title,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];

    final accountMap = {for (final a in accounts) a.id: a};

    // Header row
    final headers = [
      'ID',
      'Date',
      'Type',
      'Amount',
      'Currency',
      'Account',
      'Category',
      'Description',
      'Recurring',
      'Installment',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    // Data rows
    for (var r = 0; r < transactions.length; r++) {
      final t = transactions[r];
      final account = accountMap[t.accountId];
      final row = [
        t.id,
        Helpers.formatDate(t.date),
        t.type,
        t.amount.toString(),
        t.currency,
        account?.name ?? t.accountId,
        t.category,
        t.description ?? '',
        t.isRecurring ? 'Yes' : 'No',
        t.isInstallment ? 'Yes' : 'No',
      ];
      for (var c = 0; c < row.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(row[c]);
      }
    }

    // Summary sheet
    final summary = excel['Summary'];
    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in transactions) {
      if (t.type == 'income') totalIncome += t.amount;
      if (t.type == 'expense') totalExpense += t.amount;
    }

    summary.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('Summary');
    summary.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('Total Income');
    summary.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value =
        DoubleCellValue(totalIncome);
    summary.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('Total Expense');
    summary.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value =
        DoubleCellValue(totalExpense);
    summary.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value =
        TextCellValue('Net');
    summary.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value =
        DoubleCellValue(totalIncome - totalExpense);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/report_$timestamp.xlsx';
    final encoded = excel.encode();
    if (encoded == null) throw Exception('Failed to encode Excel file');
    await File(path).writeAsBytes(encoded);
    return path;
  }

  static Future<void> openFile(String path) async {
    await OpenFile.open(path);
  }
}
