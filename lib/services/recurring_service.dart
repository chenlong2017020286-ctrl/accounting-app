import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import 'storage_service.dart';

class RecurringService {
  static RecurringService? _instance;
  late File _file;
  List<RecurringTransaction> _items = [];

  RecurringService._();

  static RecurringService get instance {
    _instance ??= RecurringService._();
    return _instance!;
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/recurring.json');
    await load();
  }

  Future<void> load() async {
    if (!await _file.exists()) return;
    try {
      final content = await _file.readAsString();
      final list = json.decode(content) as List;
      _items = list.map((e) => RecurringTransaction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _items = [];
    }
  }

  Future<void> _persist() async {
    final data = _items.map((t) => t.toJson()).toList();
    await _file.writeAsString(json.encode(data));
  }

  List<RecurringTransaction> get all => List.unmodifiable(_items);
  List<RecurringTransaction> get active => _items.where((t) => t.active).toList();

  Future<void> add(RecurringTransaction t) async {
    _items.add(t);
    await _persist();
  }

  Future<void> toggle(String id) async {
    final idx = _items.indexWhere((t) => t.id == id);
    if (idx >= 0) {
      _items[idx].active = !_items[idx].active;
      await _persist();
    }
  }

  Future<void> delete(String id) async {
    _items.removeWhere((t) => t.id == id);
    await _persist();
  }

  /// Generate actual transactions for recurring items due today
  Future<int> generateDue() async {
    final storage = StorageService.instance;
    final now = DateTime.now();
    int count = 0;

    for (final r in active) {
      bool shouldGenerate = false;
      switch (r.frequency) {
        case RecurringFrequency.monthly:
          shouldGenerate = now.day == r.dayOfMonth;
          break;
        case RecurringFrequency.weekly:
          shouldGenerate = now.weekday == r.dayOfMonth % 7;
          break;
        case RecurringFrequency.yearly:
          shouldGenerate = now.month == r.dayOfMonth.clamp(1, 12);
          break;
      }
      if (shouldGenerate) {
        // Check if already generated today
        final todayStr = '${now.year}-${now.month}-${now.day}';
        final exists = storage.all.any((t) =>
            t.category == r.category &&
            t.amount == r.amount &&
            '${t.date.year}-${t.date.month}-${t.date.day}' == todayStr);
        if (!exists) {
          await storage.add(Transaction(
            type: r.type,
            amount: r.amount,
            category: r.category,
            note: r.note,
            date: now,
          ));
          count++;
        }
      }
    }
    return count;
  }
}
