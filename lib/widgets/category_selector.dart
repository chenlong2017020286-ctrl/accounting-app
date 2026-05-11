import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';

class CategorySelector extends StatelessWidget {
  final TransactionType type;
  final String? selected;
  final ValueChanged<String> onSelected;

  const CategorySelector({
    super.key,
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cats = CategoryService.instance.getByType(type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: cats.map((c) {
          final isSel = c.name == selected;
          return GestureDetector(
            onTap: () => onSelected(c.name),
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSel
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSel
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(c.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    c.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSel ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
