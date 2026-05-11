import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';

const List<String> _commonEmojis = [
  '🍜', '🚇', '🛍', '🏠', '🎮', '📱', '💊', '📚', '👕', '🤝', '🏃', '✈', '🐾', '📦',
  '💰', '🎯', '📈', '💼', '🧧', '📥',
  '🍔', '🍕', '☕', '🍺', '🎬', '🎵', '📺', '💻', '🖥', '📷', '🎁', '🎂',
  '🚗', '🚌', '🚲', '🚢', '🏨', '🏦', '🏪', '💈', '🔧', '🎨', '⚽', '🏀',
  '🐱', '🐶', '🌸', '🌴', '🌈', '⭐', '🔥', '💡', '🔑', '🎒', '👟', '🧢',
  '👗', '👔', '💄', '👜', '⌚', '📖', '✏', '🎓', '💪', '❤', '🎉', '🎊',
];

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _service = CategoryService.instance;

  void _refresh() => setState(() {});

  Future<bool?> _confirmDelete(CategoryModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定删除分类「${cat.icon} ${cat.name}」吗？\n已有该分类的账单不会受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.delete(cat.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除「${cat.name}」分类')),
        );
      }
      return true;
    }
    return false;
  }

  Future<void> _showCategoryDialog({CategoryModel? existing}) async {
    final isAdd = existing == null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedEmoji = existing?.icon ?? _commonEmojis[0];
    TransactionType selectedType = existing?.type ?? TransactionType.expense;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isAdd ? '添加分类' : '编辑分类'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdd) ...[
                    const Text('类型', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('支出'),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('收入'),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (s) =>
                          setDialogState(() => selectedType = s.first),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('名称', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: '分类名称',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    autofocus: isAdd,
                  ),
                  const SizedBox(height: 16),
                  const Text('图标', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: _commonEmojis.length,
                    itemBuilder: (_, i) {
                      final e = _commonEmojis[i];
                      final sel = e == selectedEmoji;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedEmoji = e),
                        child: Container(
                          decoration: BoxDecoration(
                            color: sel
                                ? Theme.of(ctx).colorScheme.primaryContainer
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('请输入分类名称')),
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'name': name,
                  'icon': selectedEmoji,
                  'type': selectedType,
                });
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final name = result['name'] as String;
    final icon = result['icon'] as String;

    if (isAdd) {
      final type = result['type'] as TransactionType;
      final ok = await _service.add(CategoryModel(
        name: name,
        icon: icon,
        type: type,
      ));
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同名分类已存在')),
        );
        return;
      }
    } else {
      existing.name = name;
      existing.icon = icon;
      final ok = await _service.update(existing);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同名分类已存在')),
        );
        return;
      }
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final expenseCats = _service.getByType(TransactionType.expense);
    final incomeCats = _service.getByType(TransactionType.income);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'reset') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('重置分类'),
                    content: const Text('将恢复默认分类，自定义分类将被删除。确定吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('重置', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true) {
                  await _service.resetDefaults();
                  _refresh();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已恢复默认分类')),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'reset', child: ListTile(leading: Icon(Icons.restart_alt), title: Text('恢复默认'))),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          _buildSection(
            context,
            title: '支出分类',
            color: Colors.red,
            items: expenseCats,
            type: TransactionType.expense,
          ),
          const Divider(height: 32, indent: 16, endIndent: 16),
          _buildSection(
            context,
            title: '收入分类',
            color: Colors.green,
            items: incomeCats,
            type: TransactionType.income,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Color color,
    required List<CategoryModel> items,
    required TransactionType type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} 个',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                '暂无分类，点击 + 添加',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final cat = items[i];
              return Dismissible(
                key: ValueKey('cat_${cat.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(cat),
                onDismissed: (_) => _refresh(),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  key: ValueKey(cat.id),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.only(left: 4, right: 12),
                    leading: ReorderableDragStartListener(
                      index: i,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.drag_handle,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          cat.name,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: Colors.grey[600],
                      onPressed: () => _showCategoryDialog(existing: cat),
                    ),
                    onTap: () => _showCategoryDialog(existing: cat),
                  ),
                ),
              );
            },
            onReorder: (old, new_) => _onReorder(old, new_, type),
          ),
      ],
    );
  }

  Future<void> _onReorder(
      int oldIndex, int newIndex, TransactionType type) async {
    await _service.reorder(oldIndex, newIndex, type);
    _refresh();
  }
}
