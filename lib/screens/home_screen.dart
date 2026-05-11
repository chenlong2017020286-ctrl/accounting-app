import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction.dart';
import 'statistics_screen.dart';
import 'ai_input_screen.dart';
import 'api_settings_screen.dart';
import 'data_management_screen.dart';
import 'budget_screen.dart';
import 'recurring_screen.dart';
import 'category_management_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const HomeScreen({super.key, this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService.instance;
  final _budget = BudgetService.instance;
  final _now = DateTime.now();
  late int _year, _month;
  List<Transaction> _transactions = [];
  List<Transaction> _filtered = [];
  final _searchCtrl = TextEditingController();
  String? _filterCategory;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _year = _now.year;
    _month = _now.month;
    _refresh();
    if (_storage.count == 0) _addSampleData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    setState(() {
      _transactions = _storage.sorted();
      _applyFilter();
    });
  }

  void _applyFilter() {
    var list = _transactions;
    if (_filterCategory != null) {
      list = list.where((t) => t.category == _filterCategory).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) =>
          t.category.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q)).toList();
    }
    _filtered = list;
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        _filterCategory = null;
        _applyFilter();
      }
    });
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
      context, MaterialPageRoute(builder: (_) => const AiInputScreen()),
    );
    if (result == true) _refresh();
  }

  Future<void> _editTransaction(Transaction t) async {
    final result = await Navigator.push<Transaction>(
      context, MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: t)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的账本'),
        actions: [
          IconButton(icon: Icon(_showSearch ? Icons.close : Icons.search), onPressed: _toggleSearch),
          IconButton(icon: const Icon(Icons.auto_awesome), onPressed: _aiInput),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'stats': Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
                case 'budget': Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen()));
                case 'recurring': Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen()));
                case 'data': Navigator.push(context, MaterialPageRoute(builder: (_) => const DataManagementScreen()));
                case 'api': Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiSettingsScreen()));
                case 'categories': Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
                case 'theme': widget.onToggleTheme?.call();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'stats', child: ListTile(leading: Icon(Icons.pie_chart), title: Text('统计'))),
              const PopupMenuItem(value: 'budget', child: ListTile(leading: Icon(Icons.account_balance_wallet), title: Text('预算'))),
              const PopupMenuItem(value: 'recurring', child: ListTile(leading: Icon(Icons.repeat), title: Text('定期账单'))),
              const PopupMenuItem(value: 'categories', child: ListTile(leading: Icon(Icons.category), title: Text('分类管理'))),
              const PopupMenuItem(value: 'data', child: ListTile(leading: Icon(Icons.storage), title: Text('数据管理'))),
              const PopupMenuItem(value: 'api', child: ListTile(leading: Icon(Icons.api), title: Text('API 设置'))),
              PopupMenuItem(value: 'theme', child: ListTile(
                leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                title: Text(isDark ? '浅色模式' : '深色模式'),
              )),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: CustomScrollView(
          slivers: [
            // Search bar
            if (_showSearch)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: '搜索分类或备注...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true, fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          suffixIcon: _filterCategory != null
                              ? Chip(label: Text(_filterCategory!, style: const TextStyle(fontSize: 11)), onDeleted: () {
                                  setState(() { _filterCategory = null; _applyFilter(); });
                                })
                              : null,
                        ),
                        onChanged: (_) => setState(_applyFilter),
                      ),
                      if (_filterCategory == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: ['全部', ...CategoryService.instance.getByType(TransactionType.expense).map((c) => c.name)].map((name) {
                                final sel = name == _filterCategory || (name == '全部' && _filterCategory == null);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(name, style: const TextStyle(fontSize: 12)),
                                    selected: sel,
                                    onSelected: (_) => setState(() {
                                      _filterCategory = name == '全部' ? null : name;
                                      _applyFilter();
                                    }),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Summary
            SliverToBoxAdapter(
              child: SummaryCard(
                income: monthIncome,
                expense: monthExpense,
                title: DateFormat('M月结余').format(DateTime(_year, _month)),
                budgetRatio: _budget.hasBudget ? _budget.usageRatio(monthExpense) : null,
                budgetAmount: _budget.hasBudget ? _budget.monthlyBudget : null,
                budgetExceeded: _budget.hasBudget && monthExpense > _budget.monthlyBudget,
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text('最近账单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${_filtered.length} 笔', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),

            // Transaction list
            _filtered.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: Text('没有匹配的账单', style: TextStyle(color: Colors.grey))),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => TransactionTile(
                        transaction: _filtered[i],
                        onTap: () => _editTransaction(_filtered[i]),
                        onDelete: () => _deleteTransaction(_filtered[i]),
                      ),
                      childCount: _filtered.length,
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
