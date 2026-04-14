import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/todo_item.dart';
import 'local_nlp_parser.dart';
import 'package:uuid/uuid.dart';

class AiParserService {
  // Claude API配置
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY'; // 需要替换为实际的API密钥
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiVersion = '2023-06-01';

  // 解析用户输入并生成待办事项
  static Future<List<TodoItem>> parseInput(String input) async {
    // 1. 首先尝试本地解析
    final localResults = await LocalNlpParser.parse(input);

    // 2. 检查本地解析结果是否完整
    if (_isParseComplete(input, localResults)) {
      return localResults;
    }

    // 3. 如果本地解析不完整，调用AI API
    try {
      final aiResults = await _parseWithAi(input);
      return aiResults;
    } catch (e) {
      // 4. AI调用失败时，返回本地解析结果
      return localResults;
    }
  }

  // 检查解析结果是否完整
  static bool _isParseComplete(String input, List<TodoItem> results) {
    if (results.isEmpty) return false;

    // 检查是否解析出了所有明显的时间信息
    final timePattern = RegExp(
      r'(\d{1,2})\s*(点|时)|'
      r'(今天|明天|后天|下周一?|下周二?|下周三?|下周四?|下周五?|下周六?|下周日?|这周一?|这周二?|这周三?|这周四?|这周五?|这周六?|这周日?|'
      r'早上|上午|中午|下午|晚上|凌晨|午夜)|'
      r'\d{4}[-/年]\d{1,2}[-/月]\d{1,2}|'
      r'(周|星期)[一二三四五六七日天]',
    );

    final matches = timePattern.allMatches(input);
    if (matches.isEmpty) return results.isNotEmpty;

    // 简单检查：如果有时间信息，应该有对应的事项
    return results.any((todo) => todo.reminderTime != null);
  }

  // 使用Claude API进行智能解析
  static Future<List<TodoItem>> _parseWithAi(String input) async {
    final prompt = '''
你是一个智能待办事项解析助手。请从用户的输入中提取出所有待办事项，并以JSON格式返回。

用户输入：$input

请按以下规则解析：
1. 识别每个待办事项的标题（简明扼要）
2. 提取时间信息，转换为ISO 8601格式（北京时间）
3. 根据事项内容推断优先级（低/中/高）
4. 生成合适的提醒内容
5. 如果有明确的提醒时间，设置reminderEnabled为true

返回格式（JSON数组）：
[
  {
    "title": "事项标题",
    "description": "详细描述",
    "reminderTime": "2024-01-01T16:00:00",
    "reminderEnabled": true,
    "priority": "medium",
    "reminderContent": "提醒内容"
  }
]

注意：
- 时间如果是"今天下午4点"，请转换为当前日期的16:00
- 时间如果是"明天早上8点"，请转换为明天日期的08:00
- 时间如果是"下周一"，请转换为下周一的09:00
- 如果没有明确时间，reminderTime设为null，reminderEnabled设为false
- priority可选值: "low", "medium", "high"
- 只返回JSON数组，不要有其他内容
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 4096,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'];

        // 提取JSON部分
        final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          final List<dynamic> jsonList = jsonDecode(jsonMatch.group(0)!);
          return jsonList.map((json) => _convertJsonToTodoItem(json)).toList();
        }
      }

      throw Exception('AI解析失败');
    } catch (e) {
      throw Exception('AI调用失败: $e');
    }
  }

  // 将JSON转换为TodoItem
  static TodoItem _convertJsonToTodoItem(Map<String, dynamic> json) {
    return TodoItem(
      id: const Uuid().v4(),
      title: json['title'] as String,
      description: json['description'] as String?,
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'] as String)
          : null,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      priority: _parsePriority(json['priority'] as String?),
      reminderContent: json['reminderContent'] as String?,
    );
  }

  // 解析优先级
  static TodoPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return TodoPriority.low;
      case 'high':
        return TodoPriority.high;
      default:
        return TodoPriority.medium;
    }
  }

  // 设置API密钥
  static void setApiKey(String apiKey) {
    // 在实际应用中，应该安全地存储API密钥
    // 这里只是示例，实际应该使用flutter_secure_storage等
  }

  // 测试API连接
  static Future<bool> testApiConnection(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 100,
          'messages': [
            {
              'role': 'user',
              'content': 'Hello',
            }
          ],
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
