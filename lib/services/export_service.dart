import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:file_picker/file_picker.dart';
import '../models/transaction.dart';
import 'storage_service.dart';

class ExportResult {
  final bool success;
  final String message;

  ExportResult({required this.success, required this.message});
}

class ExportService {
  static final _storage = StorageService.instance;

  /// Export all transactions to CSV and share
  static Future<ExportResult> exportToCsv() async {
    try {
      final txs = _storage.sorted();
      if (txs.isEmpty) {
        return ExportResult(success: false, message: '没有数据可以导出');
      }

      final buffer = StringBuffer();
      // BOM for Excel UTF-8 compatibility
      buffer.write('﻿');
      buffer.writeln('类型,金额,分类,备注,日期');

      for (final t in txs) {
        final typeStr = t.type == TransactionType.income ? '收入' : '支出';
        final note = t.note.replaceAll(',', '，').replaceAll('\n', ' ');
        final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
        buffer.writeln('$typeStr,${t.amount},${t.category},$note,$dateStr');
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/账本导出_$timestamp.csv');
      await file.writeAsString(buffer.toString(), encoding: utf8);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '账本数据导出',
      );

      return ExportResult(success: true, message: '导出成功：${txs.length} 笔账单');
    } catch (e) {
      return ExportResult(success: false, message: '导出失败：$e');
    }
  }

  /// Import transactions from a CSV file
  static Future<ExportResult> importFromCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        return ExportResult(success: false, message: '未选择文件');
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        return ExportResult(success: false, message: '无法读取文件');
      }

      final content = await File(filePath).readAsString(encoding: utf8);
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

      if (lines.length < 2) {
        return ExportResult(success: false, message: 'CSV 文件为空或格式不正确');
      }

      // Skip header row
      int count = 0;
      for (int i = 1; i < lines.length; i++) {
        final parsed = _parseCsvLine(lines[i]);
        if (parsed != null) {
          await _storage.add(parsed);
          count++;
        }
      }

      return ExportResult(success: true, message: '导入成功：$count 笔账单');
    } catch (e) {
      return ExportResult(success: false, message: '导入失败：$e');
    }
  }

  /// Export as JSON (complete data backup)
  static Future<ExportResult> exportToJson() async {
    try {
      final txs = _storage.sorted();
      if (txs.isEmpty) {
        return ExportResult(success: false, message: '没有数据可以导出');
      }

      final data = txs.map((t) => t.toJson()).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/账本备份_$timestamp.json');
      await file.writeAsString(jsonStr, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '账本数据备份',
      );

      return ExportResult(success: true, message: '备份导出成功：${txs.length} 笔');
    } catch (e) {
      return ExportResult(success: false, message: '导出失败：$e');
    }
  }

  /// Import from JSON backup
  static Future<ExportResult> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return ExportResult(success: false, message: '未选择文件');
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        return ExportResult(success: false, message: '无法读取文件');
      }

      final content = await File(filePath).readAsString(encoding: utf8);
      final list = json.decode(content) as List;
      int count = 0;
      for (final item in list) {
        try {
          final t = Transaction.fromJson(item as Map<String, dynamic>);
          await _storage.add(t);
          count++;
        } catch (_) {}
      }

      return ExportResult(success: true, message: '导入成功：$count 笔账单');
    } catch (e) {
      return ExportResult(success: false, message: '导入失败：$e');
    }
  }

  static Transaction? _parseCsvLine(String line) {
    try {
      // Handle CSV with potential commas in quoted fields
      final parts = _splitCsvLine(line);
      if (parts.length < 5) return null;

      final typeStr = parts[0].trim();
      final amount = double.tryParse(parts[1].trim());
      final category = parts[2].trim();
      final note = parts[3].trim();
      final dateStr = parts[4].trim();

      if (amount == null || amount <= 0 || category.isEmpty) return null;

      TransactionType type;
      if (typeStr == '收入' || typeStr == 'income') {
        type = TransactionType.income;
      } else {
        type = TransactionType.expense;
      }

      DateTime? date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        date = DateTime.now();
      }

      return Transaction(
        type: type,
        amount: amount,
        category: category,
        note: note,
        date: date,
      );
    } catch (_) {
      return null;
    }
  }

  static List<String> _splitCsvLine(String line) {
    // Simple CSV line splitter (handles basic quoted fields)
    final result = <String>[];
    bool inQuote = false;
    final current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuote = !inQuote;
      } else if (c == ',' && !inQuote) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }
}
