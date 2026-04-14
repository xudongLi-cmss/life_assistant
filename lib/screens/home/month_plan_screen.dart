import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/todo_item.dart';
import '../../services/storage_service_stub.dart';
import '../todo/todo_detail_screen.dart';

class MonthPlanScreen extends StatefulWidget {
  const MonthPlanScreen({super.key});

  @override
  State<MonthPlanScreen> createState() => _MonthPlanScreenState();
}

class _MonthPlanScreenState extends State<MonthPlanScreen> {
  List<TodoItem> _todos = [];
  bool _isLoading = true;
  Map<String, List<TodoItem>> _groupedTodos = {};

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);

    final username = context.read<UserProvider>().currentUser?.username;
    if (username == null) {
      setState(() => _isLoading = false);
      return;
    }

    final todos = await StorageService.getMonthTodos(username);
    _groupTodosByDate(todos);

    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  void _groupTodosByDate(List<TodoItem> todos) {
    _groupedTodos = {};

    for (final todo in todos) {
      if (todo.reminderTime == null) continue;

      final dateKey = _getDateKey(todo.reminderTime!);
      _groupedTodos.putIfAbsent(dateKey, () => []).add(todo);
    }

    // 按日期排序
    final sortedKeys = _groupedTodos.keys.toList()..sort();
    final sortedMap = <String, List<TodoItem>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = _groupedTodos[key]!;
    }
    _groupedTodos = sortedMap;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todoDate = DateTime(date.year, date.month, date.day);

    if (todoDate == today) {
      return '今天 (${date.month}月${date.day}日)';
    } else if (todoDate == tomorrow) {
      return '明天 (${date.month}月${date.day}日)';
    } else {
      final weekday = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return '${date.month}月${date.day}日 ${weekday[date.weekday - 1]}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('整月规划'),
        actions: [
          // 统计信息
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '共 ${_todos.length} 项',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '本月还没有待办事项',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groupedTodos.keys.length,
                  itemBuilder: (context, index) {
                    final dateKey = _groupedTodos.keys.elementAt(index);
                    final todos = _groupedTodos[dateKey]!;

                    return _buildDateGroup(context, dateKey, todos);
                  },
                ),
    );
  }

  Widget _buildDateGroup(
      BuildContext context, String dateKey, List<TodoItem> todos) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                dateKey,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${todos.length}项',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 该日期下的所有事项
        ...todos.map((todo) => _buildTodoCard(context, todo)),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTodoCard(BuildContext context, TodoItem todo) {
    final theme = Theme.of(context);
    final isOverdue = todo.isOverdue && !todo.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isOverdue ? 4 : 1,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TodoDetailScreen(
                todo: todo,
                onTodoUpdated: _loadTodos,
              ),
            ),
          );
          _loadTodos();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 完成状态
              Checkbox(
                value: todo.isCompleted,
                onChanged: (value) async {
                  final username =
                      context.read<UserProvider>().currentUser?.username;
                  if (username == null || value == null) return;

                  await StorageService.markTodoCompleted(todo.id, value);
                  _loadTodos();
                },
              ),
              const SizedBox(width: 8),

              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.isCompleted ? Colors.grey : null,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (todo.reminderTime != null)
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                          ),
                        if (todo.reminderTime != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(todo.reminderTime!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isOverdue
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
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
                ),
              ),

              // 箭头
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
