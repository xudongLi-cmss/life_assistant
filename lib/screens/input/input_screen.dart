import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/todo_item.dart';
import '../../services/ai_parser_service.dart';
import '../../services/storage_service_stub.dart';
import '../../services/notification_service.dart';

class InputScreen extends StatefulWidget {
  final VoidCallback? onTodosAdded;

  const InputScreen({super.key, this.onTodosAdded});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<TodoItem> _parsedTodos = [];
  bool _isParsing = false;
  bool _showExample = true;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _parseInput() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isParsing = true;
      _showExample = false;
    });

    try {
      final todos = await AiParserService.parseInput(input);

      setState(() {
        _parsedTodos = todos;
        _isParsing = false;
      });

      // 滚动到底部查看结果
      if (_parsedTodos.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _isParsing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解析失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveTodos() async {
    if (_parsedTodos.isEmpty) return;

    final username = context.read<UserProvider>().currentUser?.username;
    if (username == null) return;

    // 保存添加的项数（在清空之前）
    final addedCount = _parsedTodos.length;

    for (final todo in _parsedTodos) {
      await StorageService.addTodo(username, todo);

      if (todo.reminderEnabled && todo.reminderTime != null) {
        try {
          await NotificationService.scheduleTodoReminder(todo);
        } catch (e) {
          // 忽略通知设置失败
        }
      }
    }

    if (mounted) {
      setState(() {
        _inputController.clear();
        _parsedTodos.clear();
        _showExample = true;
      });

      widget.onTodosAdded?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 已添加 $addedCount 个事项'),
          action: SnackBarAction(
            label: '查看',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  void _clearInput() {
    setState(() {
      _inputController.clear();
      _parsedTodos.clear();
      _showExample = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '智能输入',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 输入区域
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 示例
                  if (_showExample)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '输入示例',
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '我今天下午四点要定西安到北京的高铁，在晚上20点前要发一份邮件给老板，明天早上8点开会，下周一前完成《AI行业报告分析》材料的撰写。',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '系统会自动识别时间和事项，并创建对应的待办事项和提醒。',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_showExample) const SizedBox(height: 16),

                  // 输入框
                  TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: '输入您的待办事项，例如：今天下午3点开会...',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    maxLines: null,
                    minLines: 5,
                    textInputAction: TextInputAction.newline,
                  ),

                  if (_parsedTodos.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    // 解析结果
                    Text(
                      '识别到 ${_parsedTodos.length} 个事项',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ..._parsedTodos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final todo = entry.value;
                      return _buildTodoCard(context, todo, index + 1);
                    }),

                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 80), // 底部留出按钮空间
                ],
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_inputController.text.isNotEmpty)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearInput,
                        child: const Text('清空'),
                      ),
                    ),
                  if (_inputController.text.isNotEmpty)
                    const SizedBox(width: 12),
                  Expanded(
                    flex: _parsedTodos.isEmpty ? 1 : 2,
                    child: FilledButton(
                      onPressed: _isParsing ? null : _parseInput,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isParsing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_parsedTodos.isEmpty ? '解析' : '重新解析'),
                    ),
                  ),
                  if (_parsedTodos.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _saveTodos,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('添加全部'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoCard(BuildContext context, TodoItem todo, int index) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    todo.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (todo.description != null) ...[
              const SizedBox(height: 4),
              Text(
                todo.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (todo.reminderTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: todo.isOverdue
                        ? Colors.red
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(todo.reminderTime!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: todo.isOverdue
                          ? Colors.red
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: todo.priority.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      todo.priority.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: todo.priority.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!todo.reminderEnabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '未设置提醒',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todoDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (todoDate == today) {
      dateStr = '今天';
    } else if (todoDate == tomorrow) {
      dateStr = '明天';
    } else {
      dateStr = '${dateTime.month}月${dateTime.day}日';
    }

    return '$dateStr ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
