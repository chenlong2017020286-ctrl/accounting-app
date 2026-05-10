import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/recurring_service.dart';
import '../theme/app_theme.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final _service = RecurringService.instance;

  void _refresh() => setState(() {});

  Future<void> _add() async {
    final result = await Navigator.push<RecurringTransaction>(
      context,
      MaterialPageRoute(builder: (_) => _AddRecurringScreen()),
    );
    if (result != null) {
      await _service.add(result);
      _refresh();
    }
  }

  Future<void> _toggle(RecurringTransaction t) async {
    await _service.toggle(t.id);
    _refresh();
  }

  Future<void> _delete(RecurringTransaction t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除定期账单'),
        content: Text('确定删除「${t.category}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _service.delete(t.id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _service.all;
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('定期账单')),
      body: items.isEmpty
          ? const Center(child: Text('还没有定期账单，点击 + 添加', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final t = items[i];
                final color = t.type == TransactionType.income ? AppTheme.income : AppTheme.expense;
                final sign = t.type == TransactionType.income ? '+' : '-';
                return Opacity(
                  opacity: t.active ? 1.0 : 0.5,
                  child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(t.category, style: const TextStyle(fontSize: 18))),
                    ),
                    title: Text('${sign}${fmt.format(t.amount)}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                    subtitle: Text('${t.frequencyLabel} · ${t.typeLabel}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: t.active,
                          onChanged: (_) => _toggle(t),
                          activeTrackColor: color,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _delete(t),
                        ),
                      ],
                    ),
                    onTap: () => _toggle(t),
                  ),
                ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddRecurringScreen extends StatefulWidget {
  @override
  State<_AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<_AddRecurringScreen> {
  TransactionType _type = TransactionType.expense;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  String _category = '餐饮';
  RecurringFrequency _freq = RecurringFrequency.monthly;
  int _day = 1;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加定期账单')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _typeBtn('支出', TransactionType.expense, Colors.red),
              const SizedBox(width: 12),
              _typeBtn('收入', TransactionType.income, Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '¥ ', prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              hintText: '金额',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: Colors.grey[50],
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Category selector
          const Text('分类', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: CategoryData.forType(_type).map((c) {
              final sel = c.name == _category;
              return ChoiceChip(
                label: Text('${c.icon} ${c.name}'),
                selected: sel,
                onSelected: (_) => setState(() => _category = c.name),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              hintText: '备注',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          const Text('周期', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<RecurringFrequency>(
            segments: const [
              ButtonSegment(value: RecurringFrequency.monthly, label: Text('每月')),
              ButtonSegment(value: RecurringFrequency.weekly, label: Text('每周')),
              ButtonSegment(value: RecurringFrequency.yearly, label: Text('每年')),
            ],
            selected: {_freq},
            onSelectionChanged: (s) => setState(() => _freq = s.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('日期：'),
              const SizedBox(width: 12),
              SegmentedButton<int>(
                segments: [1, 5, 10, 15, 20, 28].map((d) => ButtonSegment(value: d, label: Text('${d}号'))).toList(),
                selected: {_day},
                onSelectionChanged: (s) => setState(() => _day = s.first),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 48,
            child: FilledButton(
              onPressed: () {
                final amount = double.tryParse(_amountCtrl.text);
                if (amount == null || amount <= 0) return;
                Navigator.pop(context, RecurringTransaction(
                  type: _type, amount: amount, category: _category,
                  note: _noteCtrl.text, frequency: _freq, dayOfMonth: _day,
                ));
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('添加'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(String label, TransactionType type, Color color) {
    final sel = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? color : Colors.transparent, width: 2),
          ),
          child: Center(child: Text(label, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: sel ? color : Colors.grey,
          ))),
        ),
      ),
    );
  }
}
