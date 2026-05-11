import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
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

  void _showImagePreview(BuildContext context) {
    final file = StorageService.instance.getImageFile(transaction.imagePath!);
    if (!file.existsSync()) return;

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with pinch-to-zoom
            Center(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text('加载失败', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            // Share button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pop(ctx);
                  Share.shareXFiles(
                    [XFile(file.path)],
                    text: '小票 - ${transaction.category}',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        subtitle: Row(
          children: [
            Expanded(
              child: transaction.note.isNotEmpty
                  ? Text(transaction.note, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
                  : Text(DateFormat('MM/dd HH:mm').format(transaction.date),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ),
            if (transaction.imagePath != null)
              GestureDetector(
                onTap: () => _showImagePreview(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.camera_alt, size: 16, color: AppTheme.expense.withValues(alpha: 0.7)),
                ),
              ),
          ],
        ),
        trailing: Text(
          '$sign${fmt.format(transaction.amount)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
