import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../services/account_service.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _service = AccountService.instance;
  final _fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 1);

  @override
  Widget build(BuildContext context) {
    final accounts = _service.all;
    final totalBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);

    return Scaffold(
      appBar: AppBar(title: const Text('账户管理')),
      body: accounts.isEmpty
          ? const Center(child: Text('暂无账户', style: TextStyle(color: Colors.grey)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Total balance card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('总资产', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          _fmt.format(totalBalance),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: totalBalance >= 0 ? Colors.black : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...accounts.map((a) => _AccountCard(
                      account: a,
                      fmt: _fmt,
                      onTap: () => _editAccount(a),
                      onDelete: () => _deleteAccount(a),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addAccount() async {
    final result = await _showAccountDialog(context);
    if (result != null) {
      await _service.add(result);
      setState(() {});
    }
  }

  Future<void> _editAccount(AccountModel account) async {
    final result = await _showAccountDialog(context, existing: account);
    if (result != null) {
      await _service.update(result);
      setState(() {});
    }
  }

  Future<void> _deleteAccount(AccountModel account) async {
    if (account.id == _service.all.first.id) {
      _showSnackBar('无法删除默认账户');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账户'),
        content: Text('确定要删除「${account.name}」吗？\n关联的账单记录仍会保留，但账户余额将丢失。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.delete(account.id);
      setState(() {});
    }
  }

  Future<AccountModel?> _showAccountDialog(BuildContext context, {AccountModel? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final balanceCtrl = TextEditingController(
        text: existing != null && existing.balance > 0 ? existing.balance.toStringAsFixed(0) : '');

    String selectedIcon = existing?.icon ?? '💰';
    AccountType selectedType = existing?.type ?? AccountType.other;

    final icons = ['💰', '🏦', '📱', '💬', '💳', '👛', '🏪', '💼', '🏠', '📋'];

    return showDialog<AccountModel>(
      context: context,
      builder: (ctx) {
        final dialogIsDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? '编辑账户' : '添加账户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: '账户名称',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: dialogIsDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                  autofocus: existing == null,
                ),
                const SizedBox(height: 16),

                // Type
                const Text('账户类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<AccountType>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: dialogIsDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                  items: AccountType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 16),

                // Icon
                const Text('图标', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) {
                    final sel = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: sel ? Colors.indigo.withValues(alpha: 0.15) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: sel ? Border.all(color: Colors.indigo, width: 2) : null,
                        ),
                        child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Initial balance
                TextField(
                  controller: balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: existing != null ? '当前余额' : '初始余额',
                    prefixText: '¥ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: dialogIsDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请输入账户名称')));
                  return;
                }
                final balance = double.tryParse(balanceCtrl.text) ?? 0;
                Navigator.pop(
                  ctx,
                  AccountModel(
                    id: existing?.id,
                    name: name,
                    icon: selectedIcon,
                    type: selectedType,
                    balance: existing != null ? balance : balance,
                    createdAt: existing?.createdAt,
                  ),
                );
              },
              child: Text(existing != null ? '保存' : '添加'),
            ),
          ],
        ),
      );
    },
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final NumberFormat fmt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.fmt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除账户'),
            content: Text('确定要删除「${account.name}」吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(account.icon, style: const TextStyle(fontSize: 24))),
          ),
          title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(account.type.displayName, style: const TextStyle(fontSize: 12)),
          trailing: Text(
            fmt.format(account.balance),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: account.balance >= 0 ? Colors.black : Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}
