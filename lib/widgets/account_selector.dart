import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../services/account_service.dart';

class AccountSelector extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry? margin;

  const AccountSelector({
    super.key,
    this.selectedId,
    required this.onSelected,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final accounts = AccountService.instance.all;
    if (accounts.isEmpty) return const SizedBox.shrink();

    final selected =
        accounts.where((a) => a.id == selectedId).firstOrNull ?? accounts.first;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showPicker(context, accounts),
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          child: Row(
            children: [
              Text(selected.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                selected.name,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, List<AccountModel> accounts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择账户', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...accounts.map((a) => ListTile(
              leading: Text(a.icon, style: const TextStyle(fontSize: 28)),
              title: Text(a.name),
              subtitle: Text(a.type.displayName, style: const TextStyle(fontSize: 12)),
              trailing: a.id == selectedId ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                Navigator.pop(ctx);
                onSelected(a.id);
              },
            )),
          ],
        ),
      ),
    );
  }
}
