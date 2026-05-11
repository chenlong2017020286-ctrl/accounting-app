import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/category_model.dart';
import '../models/transaction.dart';

class CategoryService {
  static CategoryService? _instance;
  late File _file;
  final List<CategoryModel> _categories = [];
  static const String _fileName = 'categories.json';

  CategoryService._();

  static CategoryService get instance {
    _instance ??= CategoryService._();
    return _instance!;
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/$_fileName');
    await _load();
    if (_categories.isEmpty) {
      _seedDefaults();
      await _persist();
    }
  }

  Future<void> _load() async {
    if (!await _file.exists()) return;
    try {
      final content = await _file.readAsString();
      final list = json.decode(content) as List;
      _categories.addAll(
          list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('CategoryService: failed to load categories.json: $e');
    }
  }

  Future<void> _persist() async {
    final data = _categories.map((c) => c.toJson()).toList();
    await _file.writeAsString(json.encode(data));
  }

  void _seedDefaults() {
    const expenseData = [
      ('餐饮', '🍜'),
      ('交通', '🚇'),
      ('购物', '🛍'),
      ('居住', '🏠'),
      ('娱乐', '🎮'),
      ('通讯', '📱'),
      ('医疗', '💊'),
      ('教育', '📚'),
      ('服饰', '👕'),
      ('社交', '🤝'),
      ('运动', '🏃'),
      ('旅行', '✈'),
      ('宠物', '🐾'),
      ('其他支出', '📦'),
    ];
    for (int i = 0; i < expenseData.length; i++) {
      _categories.add(CategoryModel(
        name: expenseData[i].$1,
        icon: expenseData[i].$2,
        type: TransactionType.expense,
        sortOrder: i,
      ));
    }
    const incomeData = [
      ('工资', '💰'),
      ('奖金', '🎯'),
      ('理财', '📈'),
      ('兼职', '💼'),
      ('红包', '🧧'),
      ('其他收入', '📥'),
    ];
    for (int i = 0; i < incomeData.length; i++) {
      _categories.add(CategoryModel(
        name: incomeData[i].$1,
        icon: incomeData[i].$2,
        type: TransactionType.income,
        sortOrder: i,
      ));
    }
  }

  List<CategoryModel> get all => List.unmodifiable(_categories);

  List<CategoryModel> getByType(TransactionType type) {
    final result = _categories.where((c) => c.type == type).toList();
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  int _nextSortOrder(TransactionType type) {
    return getByType(type).length;
  }

  bool _hasDuplicateName(String name, [String? excludeId]) {
    return _categories.any((c) =>
        c.name == name && (excludeId == null || c.id != excludeId));
  }

  Future<bool> add(CategoryModel category) async {
    if (_hasDuplicateName(category.name)) return false;
    category.sortOrder = _nextSortOrder(category.type);
    _categories.add(category);
    await _persist();
    return true;
  }

  Future<bool> update(CategoryModel category) async {
    if (_hasDuplicateName(category.name, category.id)) return false;
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      _categories[idx] = category;
      await _persist();
      return true;
    }
    return false;
  }

  Future<void> delete(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await _persist();
  }

  Future<void> resetDefaults() async {
    _categories.clear();
    _seedDefaults();
    await _persist();
  }

  Future<void> reorder(int oldIndex, int newIndex, TransactionType type) async {
    final items = _categories.where((c) => c.type == type).toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (newIndex > oldIndex) newIndex--;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    for (int i = 0; i < items.length; i++) {
      items[i].sortOrder = i;
    }
    await _persist();
  }
}
