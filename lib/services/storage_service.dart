import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import 'account_service.dart';

class StorageService {
  static StorageService? _instance;
  late File _file;
  List<Transaction> _transactions = [];

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/accounting_data.json');
    await load();
  }

  Future<void> load() async {
    if (!await _file.exists()) return;
    try {
      final content = await _file.readAsString();
      final list = json.decode(content) as List;
      _transactions = list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _transactions = [];
    }
  }

  Future<void> _persist() async {
    final data = _transactions.map((t) => t.toJson()).toList();
    await _file.writeAsString(json.encode(data));
  }

  List<Transaction> get all => List.unmodifiable(_transactions);

  List<Transaction> sorted() {
    final copy = List<Transaction>.from(_transactions);
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  List<Transaction> forMonth(int year, int month) {
    return _transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();
  }

  double totalForMonth(int year, int month, TransactionType type) {
    return _transactions
        .where((t) => t.date.year == year && t.date.month == month && t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  List<Transaction> forAccount(String accountId) {
    return _transactions.where((t) => t.accountId == accountId).toList();
  }

  double totalForMonthByAccount(int year, int month, TransactionType type, String accountId) {
    return _transactions
        .where((t) =>
            t.date.year == year &&
            t.date.month == month &&
            t.type == type &&
            t.accountId == accountId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> categorySummary(int year, int month, TransactionType type) {
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.date.year == year && t.date.month == month && t.type == type) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Future<void> add(Transaction t) async {
    _transactions.add(t);
    if (t.accountId != null) {
      final delta = t.type == TransactionType.income ? t.amount : -t.amount;
      await AccountService.instance.adjustBalance(t.accountId!, delta);
    }
    await _persist();
  }

  Future<void> update(Transaction t) async {
    final idx = _transactions.indexWhere((x) => x.id == t.id);
    if (idx >= 0) {
      final old = _transactions[idx];

      // Reverse old transaction's balance effect
      if (old.accountId != null) {
        final reverseDelta = old.type == TransactionType.income ? -old.amount : old.amount;
        await AccountService.instance.adjustBalance(old.accountId!, reverseDelta);
      }

      _transactions[idx] = t;

      // Apply new transaction's balance effect
      if (t.accountId != null) {
        final delta = t.type == TransactionType.income ? t.amount : -t.amount;
        await AccountService.instance.adjustBalance(t.accountId!, delta);
      }

      await _persist();
    }
  }

  Future<void> delete(String id) async {
    final t = _transactions.firstWhere((x) => x.id == id);
    if (t.accountId != null) {
      final reverseDelta = t.type == TransactionType.income ? -t.amount : t.amount;
      await AccountService.instance.adjustBalance(t.accountId!, reverseDelta);
    }
    _transactions.removeWhere((t) => t.id == id);
    await _persist();
  }

  int get count => _transactions.length;
}
