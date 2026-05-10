import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TransactionType { expense, income }

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    required this.category,
    this.note = '',
    DateTime? date,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4().substring(0, 8),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        type: TransactionType.values.byName(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        note: json['note'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

class CategoryData {
  final String name;
  final String icon;
  final TransactionType type;

  const CategoryData(this.name, this.icon, this.type);

  static const List<CategoryData> expenseCategories = [
    CategoryData('餐饮', '🍜', TransactionType.expense),
    CategoryData('交通', '🚇', TransactionType.expense),
    CategoryData('购物', '🛍️', TransactionType.expense),
    CategoryData('居住', '🏠', TransactionType.expense),
    CategoryData('娱乐', '🎮', TransactionType.expense),
    CategoryData('通讯', '📱', TransactionType.expense),
    CategoryData('医疗', '💊', TransactionType.expense),
    CategoryData('教育', '📚', TransactionType.expense),
    CategoryData('服饰', '👕', TransactionType.expense),
    CategoryData('社交', '🤝', TransactionType.expense),
    CategoryData('运动', '🏃', TransactionType.expense),
    CategoryData('旅行', '✈️', TransactionType.expense),
    CategoryData('宠物', '🐾', TransactionType.expense),
    CategoryData('其他支出', '📦', TransactionType.expense),
  ];

  static const List<CategoryData> incomeCategories = [
    CategoryData('工资', '💰', TransactionType.income),
    CategoryData('奖金', '🎯', TransactionType.income),
    CategoryData('理财', '📈', TransactionType.income),
    CategoryData('兼职', '💼', TransactionType.income),
    CategoryData('红包', '🧧', TransactionType.income),
    CategoryData('其他收入', '📥', TransactionType.income),
  ];

  static List<CategoryData> forType(TransactionType type) =>
      type == TransactionType.expense ? expenseCategories : incomeCategories;
}
