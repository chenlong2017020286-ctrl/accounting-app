import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../widgets/category_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existing;

  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _type;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _type = widget.existing!.type;
      _amountCtrl = TextEditingController(text: widget.existing!.amount.toStringAsFixed(0));
      _noteCtrl = TextEditingController(text: widget.existing!.note);
      _category = widget.existing!.category;
      _date = widget.existing!.date;
    } else {
      _type = TransactionType.expense;
      _amountCtrl = TextEditingController();
      _noteCtrl = TextEditingController();
      _category = '餐饮';
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑账单' : '记一笔')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type toggle
            Row(
              children: [
                _TypeBtn(
                  label: '支出', selected: _type == TransactionType.expense,
                  color: Colors.red, onTap: () => setState(() => _type = TransactionType.expense),
                ),
                const SizedBox(width: 12),
                _TypeBtn(
                  label: '收入', selected: _type == TransactionType.income,
                  color: Colors.green, onTap: () => setState(() => _type = TransactionType.income),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: '¥ ',
                prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                hintText: '0',
                hintStyle: const TextStyle(fontSize: 36),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // Category
            const Text('分类', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CategorySelector(
              type: _type,
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 20),

            // Note
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: '备注（可选）',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                child: Text(DateFormat('yyyy/MM/dd').format(_date)),
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _type == TransactionType.expense ? Colors.red : Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isEdit ? '保存修改' : '添加账单', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }
    final t = Transaction(
      id: widget.existing?.id,
      type: _type,
      amount: amount,
      category: _category,
      note: _noteCtrl.text,
      date: _date,
      createdAt: widget.existing?.createdAt,
    );
    Navigator.pop(context, t);
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : Colors.transparent, width: 2),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: selected ? color : Colors.grey,
            )),
          ),
        ),
      ),
    );
  }
}
