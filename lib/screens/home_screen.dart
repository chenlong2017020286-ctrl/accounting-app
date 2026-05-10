import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction.dart';
import 'statistics_screen.dart';
import 'ai_input_screen.dart';
import 'api_settings_screen.dart';
import 'data_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService.instance;
  final _now = DateTime.now();
  late int _year, _month;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _year = _now.year;
    _month = _now.month;
    _refresh();
    if (_storage.count == 0) _addSampleData();
  }

  void _addSampleData() {
    final now = DateTime.now();
    for (final t in [
      Transaction(type: TransactionType.income, amount: 15000, category: '工资', note: '5月工资', date: DateTime(now.year, now.month, 1)),
      Transaction(type: TransactionType.expense, amount: 35, category: '餐饮', note: '午餐', date: DateTime(now.year, now.month, 2)),
      Transaction(type: TransactionType.expense, amount: 180, category: '交通', note: '地铁卡充值', date: DateTime(now.year, now.month, 3)),
      Transaction(type: TransactionType.expense, amount: 1200, category: '居住', note: '水电燃气', date: DateTime(now.year, now.month, 5)),
      Transaction(type: TransactionType.expense, amount: 299, category: '购物', note: '日用品', date: DateTime(now.year, now.month, 7)),
    ]) {
      _storage.add(t);
    }
    _refresh();
  }

  void _refresh() {
    setState(() => _transactions = _storage.sorted());
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (result != null) {
      await _storage.add(result);
      _refresh();
    }
  }

  Future<void> _aiInput() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AiInputScreen()),
    );
    if (result == true) _refresh();
  }

  Future<void> _editTransaction(Transaction t) async {
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: t)),
    );
    if (result != null) {
      await _storage.update(result);
      _refresh();
    }
  }

  Future<void> _deleteTransaction(Transaction t) async {
    await _storage.delete(t.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final monthExpense = _storage.totalForMonth(_year, _month, TransactionType.expense);
    final monthIncome = _storage.totalForMonth(_year, _month, TransactionType.income);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的账本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI 智能记账',
            onPressed: _aiInput,
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: '统计',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'api') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiSettingsScreen()));
              } else if (v == 'data') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DataManagementScreen()));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'data', child: ListTile(leading: Icon(Icons.storage), title: Text('数据管理'), dense: true)),
              const PopupMenuItem(value: 'api', child: ListTile(leading: Icon(Icons.api), title: Text('API 设置'), dense: true)),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SummaryCard(
                income: monthIncome,
                expense: monthExpense,
                title: DateFormat('M月结余').format(DateTime(_year, _month)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text('最近账单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('共 ${_transactions.length} 笔', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            _transactions.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: Text('还没有账单，点击 + 开始记账', style: TextStyle(color: Colors.grey))),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => TransactionTile(
                        transaction: _transactions[i],
                        onTap: () => _editTransaction(_transactions[i]),
                        onDelete: () => _deleteTransaction(_transactions[i]),
                      ),
                      childCount: _transactions.length,
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ai',
            backgroundColor: Colors.deepPurple,
            onPressed: _aiInput,
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addTransaction,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
