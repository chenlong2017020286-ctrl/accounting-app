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
  String _categoryView = 'current'; // 'current' or 'last'

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() =>
      setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
  void _nextMonth() =>
      setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));

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

  int _weekIndex(int day) {
    if (day <= 7) return 0;
    if (day <= 14) return 1;
    if (day <= 21) return 2;
    if (day <= 28) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final expense = _storage.totalForMonth(year, month, TransactionType.expense);
    final income = _storage.totalForMonth(year, month, TransactionType.income);

    // Category data depends on toggle
    final prevMonth = DateTime(year, month - 1, 1);
    final catYear = _categoryView == 'current' ? year : prevMonth.year;
    final catMonth = _categoryView == 'current' ? month : prevMonth.month;
    final catData =
        _storage.categorySummary(catYear, catMonth, TransactionType.expense);
    final catTotal = catData.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          IconButton(
            icon: _pdfLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
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
                      IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _prevMonth),
                      Text(
                          DateFormat('yyyy年M月').format(_currentMonth),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _nextMonth),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _StatBox(
                            label: '支出',
                            amount: expense,
                            color: AppTheme.expense),
                        const SizedBox(width: 16),
                        _StatBox(
                            label: '收入',
                            amount: income,
                            color: AppTheme.income),
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
                    const Text('近半年趋势',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    SizedBox(height: 200, child: _buildTrendChart()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Month-over-Month weekly bar chart ──
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('本月周度对比',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(
                            color: AppTheme.income, label: '收入'),
                        const SizedBox(width: 20),
                        _LegendDot(
                            color: AppTheme.expense, label: '支出'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(height: 220, child: _buildWeeklyBarChart()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Year-over-Year comparison ──
            _buildYearOverYear(),
            const SizedBox(height: 8),

            // ── Category pie chart with toggle ──
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('支出分类占比',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'current', label: Text('当前月')),
                        ButtonSegment(
                            value: 'last', label: Text('上月')),
                      ],
                      selected: {_categoryView},
                      onSelectionChanged: (v) =>
                          setState(() => _categoryView = v.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStateProperty.all(
                            const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (catTotal > 0)
                      SizedBox(
                        height: 300,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 160,
                              child: PieChart(
                                PieChartData(
                                  sections:
                                      _buildPieSections(catData, catTotal),
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        _buildLegend(catData, catTotal)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            _categoryView == 'current'
                                ? '本月暂无支出数据'
                                : '上月暂无支出数据',
                            style: const TextStyle(
                                color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart() {
    final allTx =
        _storage.forMonth(_currentMonth.year, _currentMonth.month);
    final weeklyInc = <int, double>{};
    final weeklyExp = <int, double>{};

    for (final t in allTx) {
      final w = _weekIndex(t.date.day);
      if (t.type == TransactionType.income) {
        weeklyInc[w] = (weeklyInc[w] ?? 0) + t.amount;
      } else {
        weeklyExp[w] = (weeklyExp[w] ?? 0) + t.amount;
      }
    }

    final allValues = [0, ...weeklyInc.values, ...weeklyExp.values];
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal > 0 ? maxVal * 1.3 : 1000.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: effectiveMax,
        groupsSpace: 4,
        barGroups: List.generate(10, (i) {
          final weekIdx = i ~/ 2;
          final isIncome = i % 2 == 0;
          final val =
              isIncome ? (weeklyInc[weekIdx] ?? 0.0) : (weeklyExp[weekIdx] ?? 0.0);
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: isIncome ? AppTheme.income : AppTheme.expense,
                width: 14,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                if (v % 2 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('第${(v ~/ 2) + 1}周',
                        style: const TextStyle(fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (v, _) =>
                  Text('¥${(v / 1000).toInt()}k',
                      style: const TextStyle(fontSize: 10)),
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: effectiveMax / 4,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildYearOverYear() {
    final lastYear = _currentMonth.year - 1;
    final month = _currentMonth.month;
    final thisYearTotal =
        _storage.totalForMonth(_currentMonth.year, month, TransactionType.expense);
    final lastYearTotal =
        _storage.totalForMonth(lastYear, month, TransactionType.expense);

    final hasLastYearData = lastYearTotal > 0;
    final maxVal = [thisYearTotal, lastYearTotal]
        .reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal > 0 ? maxVal * 1.4 : 1000.0;
    final change =
        hasLastYearData ? ((thisYearTotal - lastYearTotal) / lastYearTotal * 100) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('同比对比',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (hasLastYearData) ...[
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.center,
                    maxY: effectiveMax,
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: lastYearTotal,
                            color: Colors.blueGrey,
                            width: 36,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: thisYearTotal,
                            color: AppTheme.expense,
                            width: 36,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, _) {
                            if (v == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                    '去年${DateFormat('M月').format(_currentMonth)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12)),
                              );
                            }
                            if (v == 1) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                    '今年${DateFormat('M月').format(_currentMonth)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, _) =>
                              Text('¥${(v / 1000).toInt()}k',
                                  style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: effectiveMax / 4,
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '同比 ${change! >= 0 ? "+" : ""}${change.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: change >= 0 ? AppTheme.expense : AppTheme.income,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${_fmt.format(lastYearTotal)} → ${_fmt.format(thisYearTotal)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('暂无去年数据',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
            ],
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
      final inc =
          _storage.totalForMonth(m.year, m.month, TransactionType.income);
      final exp =
          _storage.totalForMonth(m.year, m.month, TransactionType.expense);
      spotsIncome.add(FlSpot((5 - i).toDouble(), inc));
      spotsExpense.add(FlSpot((5 - i).toDouble(), exp));
    }

    final maxVal = [
      ...spotsIncome.map((s) => s.y),
      ...spotsExpense.map((s) => s.y),
    ].reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
            show: true, horizontalInterval: maxVal > 0 ? maxVal / 4 : 1),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (v, _) =>
                  Text('¥${(v / 1000).toInt()}k',
                      style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                final m = DateTime(now.year, now.month - (5 - idx));
                return Text('${m.month}月',
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spotsIncome,
            color: AppTheme.income,
            barWidth: 2.5,
            dotData: FlDotData(show: true),
            belowBarData:
                BarAreaData(show: true, color: AppTheme.income.withValues(alpha: 0.1)),
          ),
          LineChartBarData(
            spots: spotsExpense,
            color: AppTheme.expense,
            barWidth: 2.5,
            dotData: FlDotData(show: true),
            belowBarData:
                BarAreaData(show: true, color: AppTheme.expense.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      Map<String, double> data, double total) {
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    int i = 0;
    return data.entries.map((e) {
      final pct = total > 0 ? e.value / total * 100 : 0.0;
      return PieChartSectionData(
        value: e.value,
        color: colors[i++ % colors.length],
        radius: 50,
        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  List<Widget> _buildLegend(Map<String, double> data, double total) {
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    int i = 0;
    return data.entries.map((e) {
      final pct = total > 0 ? e.value / total * 100 : 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: colors[i++ % colors.length],
                    shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(e.key,
                    style: const TextStyle(fontSize: 12))),
            Text('${_fmt.format(e.value)} (${pct.toStringAsFixed(0)}%)',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
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
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(fmt.format(amount),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
