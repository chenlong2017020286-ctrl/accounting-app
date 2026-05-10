import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/budget_service.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budget = BudgetService.instance;
  final _storage = StorageService.instance;
  late TextEditingController _ctrl;
  final _fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: _budget.hasBudget ? _budget.monthlyBudget.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = double.tryParse(_ctrl.text);
    if (v == null || v <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }
    await _budget.setMonthlyBudget(v);
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('预算已保存')));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthExpense = _storage.totalForMonth(now.year, now.month, TransactionType.expense);
    final ratio = _budget.usageRatio(monthExpense);
    final remain = _budget.remaining(monthExpense);
    final exceed = _budget.hasBudget && monthExpense > _budget.monthlyBudget;

    return Scaffold(
      appBar: AppBar(title: const Text('预算管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Budget input card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('月度支出预算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: '¥ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                            hintText: '输入预算金额',
                          ),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress card
          if (_budget.hasBudget) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('本月进度', style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                          '${_fmt.format(monthExpense)} / ${_fmt.format(_budget.monthlyBudget)}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0, 1),
                        minHeight: 14,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          exceed ? Colors.red : ratio > 0.8 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          exceed ? Icons.warning_amber : Icons.check_circle,
                          size: 16,
                          color: exceed ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          exceed
                              ? '已超出预算 ${_fmt.format(monthExpense - _budget.monthlyBudget)}'
                              : '剩余预算 ${_fmt.format(remain)}  (${(100 - ratio * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 13,
                            color: exceed ? Colors.red : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Tips
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('提示', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _tip('设置月度预算后，首页会显示预算进度条'),
                  _tip('超出预算会有红色警告提醒'),
                  _tip('预算数据仅保存在本地，不会上传'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: TextStyle(color: Colors.grey[600])),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
      ],
    ),
  );
}
