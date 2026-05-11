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
  final String? accountId;
  final String? imagePath;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    required this.category,
    this.note = '',
    DateTime? date,
    DateTime? createdAt,
    this.accountId,
    this.imagePath,
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
        if (accountId != null) 'accountId': accountId,
        if (imagePath != null) 'imagePath': imagePath,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        type: TransactionType.values.byName(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        note: json['note'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        accountId: json['accountId'] as String?,
        imagePath: json['imagePath'] as String?,
      );
}

class CategoryData {
  final String name;
  final String icon;
  final TransactionType type;

  const CategoryData(this.name, this.icon, this.type);
}
