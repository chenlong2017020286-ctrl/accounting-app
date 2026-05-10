import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class AiInputScreen extends StatefulWidget {
  const AiInputScreen({super.key});

  @override
  State<AiInputScreen> createState() => _AiInputScreenState();
}

class _AiInputScreenState extends State<AiInputScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  List<Transaction> _results = [];
  String? _error;
  bool _reviewMode = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _reviewMode = false;
    });

    final result = await AiService.parse(text);

    setState(() {
      _loading = false;
      if (result.success) {
        _results = result.transactions;
        _reviewMode = true;
      } else {
        _error = result.error;
      }
    });
  }

  Future<void> _saveAll() async {
    final storage = StorageService.instance;
    for (final t in _results) {
      await storage.add(t);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('成功添加 ${_results.length} 笔账单')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _deleteResult(int index) async {
    setState(() => _results.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('AI 智能记账')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tips card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        const Text('输入示例', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _tip('今天买菜35元，坐地铁5元'),
                    _tip('昨天买衣服花了299，晚上和朋友吃饭168'),
                    _tip('5月3号收到工资15000，交房租2500'),
                    _tip('前天打车28块，买书79，理财收益500'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Input area
            TextField(
              controller: _ctrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '输入自然语言描述...\n例如：今天买菜花了35块钱',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(16),
              ),
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 12),

            // Parse button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _loading ? null : _parse,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? '正在识别...' : '识别账单'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                ),
              ),
            ],

            // Results review
            if (_reviewMode && _results.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('识别结果', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('共 ${_results.length} 笔', style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              ..._results.asMap().entries.map((entry) {
                final i = entry.key;
                final t = entry.value;
                final color = t.type == TransactionType.income ? AppTheme.income : AppTheme.expense;
                final sign = t.type == TransactionType.income ? '+' : '-';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(t.category, style: const TextStyle(fontSize: 18))),
                    ),
                    title: Text('$sign${fmt.format(t.amount)}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                    subtitle: Text(
                      '${t.category}${t.note.isNotEmpty ? ' · ${t.note}' : ''}  ${DateFormat('MM/dd').format(t.date)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _deleteResult(i),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _saveAll,
                  icon: const Icon(Icons.check),
                  label: Text('确认添加 ${_results.length} 笔账单'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.income,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        ],
      ),
    );
  }
}
