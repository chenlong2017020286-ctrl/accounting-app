import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import 'api_config_service.dart';

class ParseResult {
  final List<Transaction> transactions;
  final String? error;

  ParseResult({required this.transactions, this.error});

  bool get success => error == null;
}

class AiService {
  static final _config = ApiConfigService.instance;

  static String get _systemPrompt => '''你是一个专业的记账解析助手。你的任务是从用户的自然语言描述中提取收支信息，返回 JSON 格式。

## 分类映射（严格使用以下分类名称）
- 支出分类：餐饮、交通、购物、居住、娱乐、通讯、医疗、教育、服饰、社交、运动、旅行、宠物、其他支出
- 收入分类：工资、奖金、理财、兼职、红包、其他收入

## 返回格式
返回一个 JSON 数组，每个元素包含：
{
  "type": "expense" 或 "income",
  "amount": 数字,
  "category": "分类名称",
  "note": "简短描述",
  "date": "YYYY-MM-DD"（可根据语义推断，如"今天""昨天""前天""5月3号"等）
}

## 规则
1. 一条文本中可能包含多笔账单，全部提取出来
2. 金额单位默认为元（块/元），如"35块"→35，"150"→150
3. 如有歧义或无法识别的部分，跳过该项
4. 如果没有明确说明日期，使用今天日期
5. 只返回 JSON 数组，不要其他文字

## 示例
输入："今天买菜花了35块钱，坐地铁5块钱，下午收到工资15000"
输出：
[
  {"type": "expense", "amount": 35, "category": "餐饮", "note": "买菜", "date": "2026-05-10"},
  {"type": "expense", "amount": 5, "category": "交通", "note": "坐地铁", "date": "2026-05-10"},
  {"type": "income", "amount": 15000, "category": "工资", "note": "", "date": "2026-05-10"}
]
''';

  static Future<ParseResult> parse(String text) async {
    if (!_config.isConfigured) {
      return ParseResult(transactions: [], error: '请先在设置中配置 API');
    }

    try {
      final resp = await http.post(
        Uri.parse('${_config.endpoint}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
        },
        body: json.encode({
          'model': _config.model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': '当前日期为 ${DateTime.now().year} 年 ${DateTime.now().month} 月 ${DateTime.now().day} 日\n\n$text'},
          ],
          'temperature': 0.1,
          'max_tokens': 1024,
        }),
        // DeepSeek API 兼容 OpenAI 格式，超时设为 30 秒
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        final body = json.decode(resp.body);
        final errMsg = body['error']?['message'] ?? 'API 请求失败 (${resp.statusCode})';
        return ParseResult(transactions: [], error: errMsg);
      }

      final body = json.decode(resp.body);
      final content = body['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        return ParseResult(transactions: [], error: 'API 返回为空');
      }

      return _parseResponse(content);
    } catch (e) {
      return ParseResult(transactions: [], error: '请求失败：${e.toString()}');
    }
  }

  static ParseResult _parseResponse(String content) {
    // Extract JSON array from response (handle possible markdown wrapping)
    final jsonStr = _extractJson(content);
    if (jsonStr == null) {
      return ParseResult(transactions: [], error: '无法解析 AI 返回结果');
    }

    try {
      final list = json.decode(jsonStr) as List;
      final txs = <Transaction>[];
      for (final item in list) {
        final typeStr = item['type'] as String?;
        final amount = (item['amount'] as num?)?.toDouble();
        final category = item['category'] as String?;
        final note = item['note'] as String? ?? '';
        String dateStr = item['date'] as String? ?? '';

        if (typeStr == null || amount == null || category == null) continue;
        if (amount <= 0) continue;

        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = DateTime.now();
        }

        txs.add(Transaction(
          type: typeStr == 'income' ? TransactionType.income : TransactionType.expense,
          amount: amount,
          category: category,
          note: note,
          date: date,
        ));
      }

      if (txs.isEmpty) {
        return ParseResult(transactions: [], error: '未能从描述中识别出有效账单');
      }
      return ParseResult(transactions: txs);
    } catch (_) {
      return ParseResult(transactions: [], error: '解析结果格式异常');
    }
  }

  static String? _extractJson(String text) {
    // Try to find JSON array in the text
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return null;
  }
}
