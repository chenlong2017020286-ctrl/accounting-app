import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_config_service.dart';
import '../theme/app_theme.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  late TextEditingController _endpointCtrl;
  late TextEditingController _keyCtrl;
  late TextEditingController _modelCtrl;
  final _config = ApiConfigService.instance;
  bool _keyVisible = false;
  bool _saved = false;
  bool _testLoading = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _endpointCtrl = TextEditingController(text: _config.endpoint);
    _keyCtrl = TextEditingController(text: _config.apiKey);
    _modelCtrl = TextEditingController(text: _config.model);
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _keyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _config.setEndpoint(_endpointCtrl.text.trim());
    await _config.setApiKey(_keyCtrl.text.trim());
    await _config.setModel(_modelCtrl.text.trim());
    setState(() => _saved = true);
  }

  Future<void> _testApi() async {
    setState(() {
      _testLoading = true;
      _testResult = null;
    });

    try {
      final resp = await http
          .post(
            Uri.parse('${_endpointCtrl.text.trim()}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_keyCtrl.text.trim()}',
            },
            body: json.encode({
              'model': _modelCtrl.text.trim(),
              'messages': [{'role': 'user', 'content': 'Hi'}],
              'max_tokens': 5,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        setState(() => _testResult = '✅ 连接成功');
      } else {
        final body = json.decode(resp.body);
        final msg = body['error']?['message'] ?? 'HTTP ${resp.statusCode}';
        setState(() => _testResult = '❌ $msg');
      }
    } catch (e) {
      setState(() => _testResult = '❌ 连接失败：$e');
    } finally {
      _testLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 设置'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('API 地址'),
          const SizedBox(height: 6),
          TextField(
            controller: _endpointCtrl,
            decoration: _inputDec('https://api.deepseek.com'),
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
          ),
          const SizedBox(height: 20),

          const _SectionTitle('API Key'),
          const SizedBox(height: 6),
          TextField(
            controller: _keyCtrl,
            obscureText: !_keyVisible,
            decoration: _inputDec('sk-xxxxxxxxxx').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _keyVisible = !_keyVisible),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const _SectionTitle('模型名称'),
          const SizedBox(height: 6),
          TextField(
            controller: _modelCtrl,
            decoration: _inputDec('deepseek-chat'),
          ),
          const SizedBox(height: 6),
          const Text('常见模型：deepseek-chat、deepseek-reasoner',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),

          if (_saved)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Text('配置已保存', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          if (_saved) const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _testLoading ? null : _testApi,
              icon: _testLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_find),
              label: Text(_testLoading ? '测试中...' : '测试连接'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testResult!.startsWith('✅') ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _testResult!.startsWith('✅') ? Colors.green[200]! : Colors.red[200]!,
                ),
              ),
              child: Text(_testResult!, style: TextStyle(
                fontSize: 13,
                color: _testResult!.startsWith('✅') ? Colors.green[800] : Colors.red[800],
              )),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
  }
}
