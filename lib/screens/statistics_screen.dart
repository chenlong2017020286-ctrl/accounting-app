import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/pdf_export_service.dart';
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
  bool _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
  void _nextMonth() => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));

  Future<void> _exportPdf() async {
    setState(() => _pdfLoading = true);
    try {
      await PdfExportService.shareReport(_currentMonth.year, _currentMonth.month);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    setState(() => _pdfLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final expense = _storage.totalForMonth(_currentMonth.year, _currentMonth.month, TransactionType.expense);
    final income = _storage.totalForMonth(_currentMonth.year, _currentMonth.month, TransactionType.income);
    final catData = _storage.categorySummary(_currentMonth.year, _currentMonth.month, TransactionType.expense);
    final total = catData.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          IconButton(
            icon: _pdfLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf),
            tooltip: '导出 PDF 报告',
            onPressed: _pdfLoading ? null : _exportPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Month nav + summary ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
                      Text(DateFormat('yyyy年M月').format(_currentMonth),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _StatBox(label: '支出', amount: expense, color: AppTheme.expense),
                        const SizedBox(width: 16),
                        _StatBox(label: '收入', amount: income, color: AppTheme.income),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Monthly trend line chart ──
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('近半年趋势', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    SizedBox(height: 200, child: _buildTrendChart()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Pie chart ──
            if (total > 0)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('支出分类占比', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 300,
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
                            Expanded(child: SingleChildScrollView(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildLegend(catData, total)),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Card(
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('本月暂无支出数据', style: TextStyle(color: AppTheme.textSecondary))),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    final now = DateTime.now();
    final spotsIncome = <FlSpot>[];
    final spotsExpense = <FlSpot>[];

    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final inc = _storage.totalForMonth(m.year, m.month, TransactionType.income);
      final exp = _storage.totalForMonth(m.year, m.month, TransactionType.expense);
      spotsIncome.add(FlSpot((5 - i).toDouble(), inc));
      spotsExpense.add(FlSpot((5 - i).toDouble(), exp));
    }

    final maxVal = [
      ...spotsIncome.map((s) => s.y),
      ...spotsExpense.map((s) => s.y),
    ].reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, horizontalInterval: maxVal > 0 ? maxVal / 4 : 1),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 50,
            getTitlesWidget: (v, _) => Text('¥${(v / 1000).toInt()}k', style: const TextStyle(fontSize: 10)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            interval: 1,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              final m = DateTime(now.year, now.month - (5 - idx));
              return Text('${m.month}月', style: const TextStyle(fontSize: 10));
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spotsIncome,
            color: AppTheme.income,
            barWidth: 2.5,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppTheme.income.withValues(alpha: 0.1)),
          ),
          LineChartBarData(
            spots: spotsExpense,
            color: AppTheme.expense,
            barWidth: 2.5,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppTheme.expense.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data, double total) {
    const colors = [
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
    const colors = [
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
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: colors[i++ % colors.length], shape: BoxShape.circle)),
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
