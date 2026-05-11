import 'package:uuid/uuid.dart';
import 'transaction.dart';

const _uuid = Uuid();

class CategoryModel {
  final String id;
  String name;
  String icon;
  TransactionType type;
  int sortOrder;

  CategoryModel({
    String? id,
    required this.name,
    required this.icon,
    required this.type,
    this.sortOrder = 0,
  }) : id = id ?? _uuid.v4().substring(0, 8);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'type': type.name,
        'sortOrder': sortOrder,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        type: TransactionType.values.byName(json['type'] as String),
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}
