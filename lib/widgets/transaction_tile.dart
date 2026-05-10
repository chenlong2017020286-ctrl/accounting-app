import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = transaction.type == TransactionType.income ? AppTheme.income : AppTheme.expense;
    final sign = transaction.type == TransactionType.income ? '+' : '-';
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除记录'),
            content: const Text('确定要删除这条账单吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(transaction.category, style: const TextStyle(fontSize: 20))),
        ),
        title: Text(transaction.category, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: transaction.note.isNotEmpty
            ? Text(transaction.note, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
            : Text(DateFormat('MM/dd HH:mm').format(transaction.date),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: Text(
          '$sign${fmt.format(transaction.amount)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
