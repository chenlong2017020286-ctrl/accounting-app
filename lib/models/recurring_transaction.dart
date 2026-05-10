import 'package:uuid/uuid.dart';
import 'transaction.dart';

const _uuid = Uuid();

enum RecurringFrequency { monthly, weekly, yearly }

class RecurringTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final String note;
  final RecurringFrequency frequency;
  final int dayOfMonth;
  final DateTime created;
  bool active;

  RecurringTransaction({
    String? id,
    required this.type,
    required this.amount,
    required this.category,
    this.note = '',
    this.frequency = RecurringFrequency.monthly,
    this.dayOfMonth = 1,
    DateTime? created,
    this.active = true,
  })  : id = id ?? _uuid.v4().substring(0, 8),
        created = created ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'category': category,
        'note': note,
        'frequency': frequency.name,
        'dayOfMonth': dayOfMonth,
        'created': created.toIso8601String(),
        'active': active,
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) => RecurringTransaction(
        id: json['id'] as String,
        type: TransactionType.values.byName(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        note: json['note'] as String? ?? '',
        frequency: RecurringFrequency.values.byName(json['frequency'] as String? ?? 'monthly'),
        dayOfMonth: json['dayOfMonth'] as int? ?? 1,
        created: DateTime.tryParse(json['created'] as String? ?? ''),
        active: json['active'] as bool? ?? true,
      );

  String get frequencyLabel {
    switch (frequency) {
      case RecurringFrequency.monthly:
        return '每月${dayOfMonth}号';
      case RecurringFrequency.weekly:
        return '每周';
      case RecurringFrequency.yearly:
        return '每年${dayOfMonth}月';
    }
  }

  String get typeLabel => type == TransactionType.income ? '收入' : '支出';
}
