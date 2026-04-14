import 'package:intl/intl.dart';
import '../models/todo_item.dart';
import 'package:uuid/uuid.dart';

/// 本地NLP解析器 - 用于基础的事项解析
/// 当本地解析失败或结果不完整时，会调用AI API
class LocalNlpParser {
  // 解析用户输入
  static Future<List<TodoItem>> parse(String input) async {
    final todos = <TodoItem>[];

    // 使用正则表达式分割多个事项
    final segments = _splitIntoSegments(input);

    for (final segment in segments) {
      final todo = await _parseSegment(segment.trim());
      if (todo != null) {
        todos.add(todo);
      }
    }

    return todos;
  }

  // 将输入分割成多个事项片段
  static List<String> _splitIntoSegments(String input) {
    final segments = <String>[];

    // 使用常见的分隔符分割
    final separators = [
      RegExp(r'[，,、]\s*'), // 中文逗号、英文逗号、顿号
      RegExp(r'[。.]\s*'), // 句号
      RegExp(r'[；;]\s*'), // 分号
      RegExp(r'\n+'), // 换行
      RegExp(r'，(?=\s*[明今后周上下早午晚]\D)'), // 特殊处理：逗号后跟时间词
    ];

    var current = input;
    for (final sep in separators) {
      current = current.replaceAll(sep, '|||');
    }

    segments.addAll(current.split('|||').where((s) => s.trim().isNotEmpty));

    return segments;
  }

  // 解析单个片段
  static Future<TodoItem?> _parseSegment(String segment) async {
    if (segment.trim().isEmpty) return null;

    // 提取时间信息
    final timeInfo = _extractTime(segment);

    // 提取事项标题
    final title = _extractTitle(segment, timeInfo);

    // 推断优先级
    final priority = _inferPriority(segment);

    // 生成提醒内容
    final reminderContent = _generateReminderContent(title, timeInfo);

    return TodoItem(
      id: const Uuid().v4(),
      title: title,
      description: segment,
      reminderTime: timeInfo,
      reminderEnabled: timeInfo != null,
      priority: priority,
      reminderContent: reminderContent,
    );
  }

  // 提取时间信息
  static DateTime? _extractTime(String text) {
    final now = DateTime.now();

    // 匹配模式：
    // 1. 今天下午4点 / 今天16点
    // 2. 明天早上8点
    // 3. 下周一
    // 4. 20点
    // 5. 晚上8点前（表示截止时间）

    final patterns = [
      // 具体日期+时间
      RegExp(r'(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})[日号]?\s*(\d{1,2})[:：点](\d{2})?'),
      RegExp(r'(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})[日号]?'),

      // 相对日期+时间（带或不带上午/下午关键词）
      RegExp(r'(今天|今日)(上午|早上|下午|晚上|中午|凌晨)?\s*(\d{1,2})[:：点](\d{2})?'),
      RegExp(r'(明天|明日)(上午|早上|下午|晚上|中午|凌晨)?\s*(\d{1,2})[:：点](\d{2})?'),
      RegExp(r'(后天)(上午|早上|下午|晚上|中午|凌晨)?\s*(\d{1,2})[:：点](\d{2})?'),

      // 星期+时间（带或不带上午/下午关键词）
      RegExp(r'(下?(周|星期)[一二三四五六七日天])(上午|早上|下午|晚上|中午|凌晨)?\s*(\d{1,2})[:：点](\d{2})?'),

      // 只有时间（带上午/下午/晚上等关键词）
      RegExp(r'(上午|早上|早间)?\s*(\d{1,2})[:：点](\d{2})?\s*(前)?'),
      RegExp(r'(下午|午间)\s*(\d{1,2})[:：点](\d{2})?\s*(前)?'),
      RegExp(r'(晚上|晚间|夜间)\s*(\d{1,2})[:：点](\d{2})?\s*(前)?'),
      RegExp(r'(中午|午间)\s*(\d{1,2})[:：点](\d{2})?\s*(前)?'),

      // 纯数字时间（24小时制或12小时制，无关键词）
      RegExp(r'^(\d{1,2})[:：点](\d{2})?\s*(前|后)?'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parseTimeMatch(match, now);
      }
    }

    // 特殊处理：星期几
    final weekdayMatch = RegExp(r'(下?(周|星期)[一二三四五六七日天])').firstMatch(text);
    if (weekdayMatch != null) {
      return _parseWeekday(weekdayMatch.group(1)!, now);
    }

    // 特殊处理：今天、明天、后天
    if (text.contains('今天') || text.contains('今日')) {
      return now;
    }
    if (text.contains('明天') || text.contains('明日')) {
      return now.add(const Duration(days: 1));
    }
    if (text.contains('后天')) {
      return now.add(const Duration(days: 2));
    }

    return null;
  }

  // 解析时间匹配结果
  static DateTime? _parseTimeMatch(Match match, DateTime now) {
    try {
      // 获取所有可用的捕获组
      final groupCount = match.groupCount;
      final groups = <String?>[];
      for (int i = 1; i <= groupCount; i++) {
        groups.add(match.group(i));
      }
      // 填充到至少8个元素
      while (groups.length < 8) {
        groups.add(null);
      }

      // 具体日期 (检查是否为数字格式)
      if (groups[0] != null && groups[1] != null && groups[2] != null) {
        // 检查groups[0]是否为4位数字
        if (RegExp(r'^\d{4}$').hasMatch(groups[0]!)) {
          final year = int.parse(groups[0]!);
          final month = int.parse(groups[1]!);
          final day = int.parse(groups[2]!);

          if (groups[3] != null) {
            // 有具体时间
            final hour = int.parse(groups[3]!);
            final minute = groups[4] != null ? int.parse(groups[4]!) : 0;
            return DateTime(year, month, day, hour, minute);
          }
          return DateTime(year, month, day, 9, 0); // 默认上午9点
        }
      }

      // 相对日期
      if (groups[0] != null) {
        final dateKeyword = groups[0]!;
        DateTime targetDate = now;

        if (dateKeyword.contains('明') || dateKeyword.contains('明日')) {
          targetDate = now.add(const Duration(days: 1));
        } else if (dateKeyword.contains('后')) {
          targetDate = now.add(const Duration(days: 2));
        }

        final timeKeyword = groups[1];
        int hour = 9;
        int minute = 0;

        if (groups[2] != null) {
          hour = int.parse(groups[2]!);
          minute = groups[3] != null ? int.parse(groups[3]!) : 0;

          // 根据时间关键词调整小时
          if (timeKeyword != null) {
            hour = _adjustHourByTimeKeyword(hour, timeKeyword);
          } else {
            // 没有时间关键词时，根据小时数判断
            // 9点以下认为是上午，12点以上认为是下午（24小时制）
            if (hour <= 8) {
              // 小时 <= 8，认为是早上/凌晨，保持原值
            } else if (hour <= 11) {
              // 9-11点，保持原值（上午）
            } else if (hour == 12) {
              // 12点，中午
            }
            // 13点及以上已经是24小时制，无需调整
          }
        }

        return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
      }

      // 星期
      if (groups[0] != null) {
        final weekdayStr = groups[0]!;
        return _parseWeekday(weekdayStr, now);
      }

      // 只有时间
      if (groups[0] != null || groups[1] != null) {
        final timeKeyword = groups[0];
        int hour = int.parse(groups[1]!);
        final minute = groups[2] != null ? int.parse(groups[2]!) : 0;

        if (timeKeyword != null) {
          hour = _adjustHourByTimeKeyword(hour, timeKeyword);
        }

        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  // 根据时间关键词调整小时
  static int _adjustHourByTimeKeyword(int hour, String keyword) {
    if (keyword.contains('上午') || keyword.contains('早上')) {
      return hour > 12 ? hour - 12 : hour;
    } else if (keyword.contains('下午') || keyword.contains('晚上')) {
      return hour < 12 ? hour + 12 : hour;
    }
    return hour;
  }

  // 解析星期几
  static DateTime _parseWeekday(String weekdayStr, DateTime now) {
    final weekdayMap = {
      '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7,
    };

    final match = RegExp(r'([一二三四五六七日天])').firstMatch(weekdayStr);
    if (match == null) return now;

    final targetWeekday = weekdayMap[match.group(1)] ?? 1;
    final isNextWeek = weekdayStr.contains('下');

    int daysToAdd = targetWeekday - now.weekday;
    if (daysToAdd <= 0) daysToAdd += 7;
    if (isNextWeek) daysToAdd += 7;

    return now.add(Duration(days: daysToAdd));
  }

  // 提取事项标题
  static String _extractTitle(String segment, DateTime? timeInfo) {
    // 移除时间信息，保留核心内容
    var title = segment;

    // 移除时间关键词
    final timePatterns = [
      RegExp(r'(今天|明天|后天|今天|明天|后天)(上午|下午|晚上|中午|凌晨)?\s*\d{1,2}[:：点]\d{0,2}'),
      RegExp(r'(下?(周|星期)[一二三四五六七日天])(上午|下午|晚上|中午|凌晨)?\s*\d{1,2}[:：点]\d{0,2}'),
      RegExp(r'\d{1,2}[:：点]\d{0,2}(前|后)?'),
      RegExp(r'(今天|明天|后天|下?(周|星期)[一二三四五六七日天])'),
      RegExp(r'\d{4}[-/年]\d{1,2}[-/月]\d{1,2}[日号]?'),
    ];

    for (final pattern in timePatterns) {
      title = title.replaceAll(pattern, '').trim();
    }

    // 清理标题
    title = title.replaceAll(RegExp(r'^[，,、。.;;]+'), '').trim();
    title = title.replaceAll(RegExp(r'[，,、。.;;]+$'), '').trim();

    // 如果标题为空或太短，使用原文
    if (title.length < 2) {
      title = segment.length > 20
          ? '${segment.substring(0, 20)}...'
          : segment;
    }

    return title;
  }

  // 推断优先级
  static TodoPriority _inferPriority(String text) {
    final lowerText = text.toLowerCase();

    // 高优先级关键词
    final highKeywords = [
      '重要', '紧急', '马上', '立即', '赶紧', '老板', '客户',
      'deadline', '截止', '务必', '一定', '必须',
    ];

    // 低优先级关键词
    final lowKeywords = [
      '有时间', '空闲', '可以', '尽量', '如果', '可能', '或许',
      '看看', '考虑', '有空',
    ];

    for (final keyword in highKeywords) {
      if (lowerText.contains(keyword)) return TodoPriority.high;
    }

    for (final keyword in lowKeywords) {
      if (lowerText.contains(keyword)) return TodoPriority.low;
    }

    return TodoPriority.medium;
  }

  // 生成提醒内容
  static String _generateReminderContent(String title, DateTime? timeInfo) {
    if (timeInfo == null) return '提醒：$title';

    final now = DateTime.now();
    final format = DateFormat('HH:mm');

    if (timeInfo.day == now.day &&
        timeInfo.month == now.month &&
        timeInfo.year == now.year) {
      return '今天 ${format.format(timeInfo)}：$title';
    }

    final dateFormat = DateFormat('M月d日 HH:mm');
    return '${dateFormat.format(timeInfo)}：$title';
  }
}
