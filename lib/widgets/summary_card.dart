import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final String title;

  const SummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 1);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(
              fmt.format(balance),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? AppTheme.textPrimary : AppTheme.expense,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Label(icon: Icons.arrow_upward, label: '收入', amount: income, color: AppTheme.income),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(height: 40, child: VerticalDivider(thickness: 1)),
                ),
                _Label(icon: Icons.arrow_downward, label: '支出', amount: expense, color: AppTheme.expense),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _Label({required this.icon, required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text(fmt.format(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
