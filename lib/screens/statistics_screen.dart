import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _currentMonth;
  final _storage = StorageService.instance;
  final _fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
  void _nextMonth() => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final expense = _storage.totalForMonth(_currentMonth.year, _currentMonth.month, TransactionType.expense);
    final income = _storage.totalForMonth(_currentMonth.year, _currentMonth.month, TransactionType.income);
    final catData = _storage.categorySummary(_currentMonth.year, _currentMonth.month, TransactionType.expense);
    final total = catData.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: Column(
        children: [
          // Month nav
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
                Text(
                  DateFormat('yyyy年M月').format(_currentMonth),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
              ],
            ),
          ),
          // Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _StatBox(label: '支出', amount: expense, color: AppTheme.expense),
                const SizedBox(width: 16),
                _StatBox(label: '收入', amount: income, color: AppTheme.income),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Chart
          Expanded(
            child: catData.isEmpty
                ? const Center(child: Text('本月暂无支出数据', style: TextStyle(color: AppTheme.textSecondary)))
                : Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('支出分类占比', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          Expanded(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 160,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _buildPieSections(catData, total),
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _buildLegend(catData, total),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data, double total) {
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.indigo, Colors.amber, Colors.cyan,
    ];
    int i = 0;
    return data.entries.map((e) {
      final pct = total > 0 ? e.value / total * 100 : 0.0;
      return PieChartSectionData(
        value: e.value,
        color: colors[i++ % colors.length],
        radius: 50,
        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  List<Widget> _buildLegend(Map<String, double> data, double total) {
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.indigo, Colors.amber, Colors.cyan,
    ];
    int i = 0;
    return data.entries.map((e) {
      final pct = total > 0 ? e.value / total * 100 : 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(
              color: colors[i++ % colors.length], shape: BoxShape.circle,
            )),
            const SizedBox(width: 8),
            Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))),
            Text('${_fmt.format(e.value)} (${pct.toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }).toList();
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _StatBox({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(fmt.format(amount), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
