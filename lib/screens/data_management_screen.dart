import 'package:flutter/material.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final _storage = StorageService.instance;
  bool _loading = false;

  Future<void> _exportCsv() async {
    setState(() => _loading = true);
    final result = await ExportService.exportToCsv();
    setState(() => _loading = false);
    if (!mounted) return;
    _showResult(result);
  }

  Future<void> _importCsv() async {
    setState(() => _loading = true);
    final result = await ExportService.importFromCsv();
    setState(() => _loading = false);
    if (!mounted) return;
    _showResult(result);
    setState(() {});
  }

  Future<void> _exportJson() async {
    setState(() => _loading = true);
    final result = await ExportService.exportToJson();
    setState(() => _loading = false);
    if (!mounted) return;
    _showResult(result);
  }

  Future<void> _importJson() async {
    setState(() => _loading = true);
    final result = await ExportService.importFromJson();
    setState(() => _loading = false);
    if (!mounted) return;
    _showResult(result);
    setState(() {});
  }

  void _showResult(ExportResult r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(r.message),
        backgroundColor: r.success ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _storage.count;
    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.storage, size: 40, color: AppTheme.primary.withValues(alpha: 0.7)),
                  const SizedBox(height: 12),
                  Text('当前数据', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('$count 笔账单', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('CSV 格式（推荐，可用 Excel 打开编辑）'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.file_upload_outlined,
                  label: '导入 CSV',
                  color: Colors.blue,
                  onTap: _loading ? null : _importCsv,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.file_download_outlined,
                  label: '导出 CSV',
                  color: Colors.green,
                  onTap: _loading ? null : _exportCsv,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CSV 文件可用 Excel、WPS、记事本等打开编辑。'
                    '编辑后再次导入即可更新数据。',
                    style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('JSON 格式（完整数据备份与恢复）'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.restore,
                  label: '导入备份',
                  color: Colors.orange,
                  onTap: _loading ? null : _importJson,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.backup,
                  label: '导出备份',
                  color: Colors.purple,
                  onTap: _loading ? null : _exportJson,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Data protection info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, size: 18, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text('数据保护说明', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow('数据存储在 App 独立目录，覆盖安装不会丢失'),
                  _infoRow('支持 iTunes 文件共享，可通过电脑访问导出文件'),
                  _infoRow('建议定期导出备份，以防数据丢失'),
                  _infoRow('导入 CSV 时请注意保持列格式：类型,金额,分类,备注,日期'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _infoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.green[700])),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
