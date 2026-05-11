import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class PdfExportService {
  static final _storage = StorageService.instance;

  static Future<String> generateMonthlyReport(int year, int month) async {
    final txs = _storage.forMonth(year, month);
    if (txs.isEmpty) {
      throw Exception('$year年$month月没有数据');
    }

    final income = _storage.totalForMonth(year, month, TransactionType.income);
    final expense = _storage.totalForMonth(year, month, TransactionType.expense);
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final dateFmt = DateFormat('yyyy/MM/dd');

    // Load Chinese font to fix garbled text in PDF
    final font = await PdfGoogleFonts.notoSansSCRegular();
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: font));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('月度账单报告', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('$year年$month月', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statBox('收入', fmt.format(income), PdfColors.green700),
                _statBox('支出', fmt.format(expense), PdfColors.red700),
                _statBox('结余', fmt.format(income - expense), PdfColors.blue700),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text('生成于 ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        ),
        build: (context) => [
          // Category summary
          pw.Header(text: '支出分类', level: 1),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            cellStyle: const pw.TextStyle(fontSize: 11),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellHeight: 28,
            columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(2), 2: const pw.FlexColumnWidth(2)},
            headers: ['分类', '金额', '占比'],
            data: _categoryRows(expense, year, month),
          ),
          pw.SizedBox(height: 24),
          pw.Header(text: '账单明细', level: 1),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellHeight: 24,
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(3), 3: const pw.FlexColumnWidth(2)},
            headers: ['日期', '类型', '分类', '金额'],
            data: txs.map((t) => [
              dateFmt.format(t.date),
              t.type == TransactionType.income ? '收入' : '支出',
              '${t.category}${t.note.isNotEmpty ? '(${t.note})' : ''}',
              fmt.format(t.amount),
            ]).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/月度报告_$year${month.toString().padLeft(2, '0')}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  static List<List<String>> _categoryRows(double total, int year, int month) {
    final cats = _storage.categorySummary(year, month, TransactionType.expense);
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    if (total == 0) return [['无', '¥0', '0%']];
    return cats.entries.map((e) => [
      e.key,
      fmt.format(e.value),
      '${(e.value / total * 100).toStringAsFixed(1)}%',
    ]).toList();
  }

  static pw.Widget _statBox(String label, String amount, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF5F5F5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(amount, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static Future<void> shareReport(int year, int month) async {
    final path = await generateMonthlyReport(year, month);
    await Printing.sharePdf(
      bytes: await File(path).readAsBytes(),
      filename: '月度报告_$year${month.toString().padLeft(2, '0')}.pdf',
    );
  }
}
