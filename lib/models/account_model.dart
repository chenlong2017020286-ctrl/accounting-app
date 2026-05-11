import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AccountType {
  cash,
  bank,
  alipay,
  wechat,
  creditCard,
  other;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return '现金';
      case AccountType.bank:
        return '银行卡';
      case AccountType.alipay:
        return '支付宝';
      case AccountType.wechat:
        return '微信';
      case AccountType.creditCard:
        return '信用卡';
      case AccountType.other:
        return '其他';
    }
  }
}

class AccountModel {
  final String id;
  String name;
  String icon;
  AccountType type;
  double balance;
  final DateTime createdAt;

  AccountModel({
    String? id,
    required this.name,
    required this.icon,
    required this.type,
    this.balance = 0,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4().substring(0, 8),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'type': type.name,
        'balance': balance,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        type: AccountType.values.byName(json['type'] as String),
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  AccountModel copyWith({
    String? name,
    String? icon,
    AccountType? type,
    double? balance,
  }) {
    return AccountModel(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      createdAt: createdAt,
    );
  }
}
