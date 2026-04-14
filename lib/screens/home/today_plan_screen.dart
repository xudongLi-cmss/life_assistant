import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/todo_item.dart';
import '../../services/storage_service_stub.dart';
import '../todo/todo_detail_screen.dart';

class TodayPlanScreen extends StatefulWidget {
  const TodayPlanScreen({super.key});

  @override
  State<TodayPlanScreen> createState() => _TodayPlanScreenState();
}

class _TodayPlanScreenState extends State<TodayPlanScreen> {
  List<TodoItem> _todos = [];
  bool _isLoading = true;

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

    final todos = await StorageService.getTodayTodos(username);
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日规划'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.today_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '今天还没有待办事项',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _todos.length,
                  itemBuilder: (context, index) {
                    final todo = _todos[index];
                    return _buildTodoCard(context, todo);
                  },
                ),
    );
  }

  Widget _buildTodoCard(BuildContext context, TodoItem todo) {
    final theme = Theme.of(context);
    final isOverdue = todo.isOverdue && !todo.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
          padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 12),

              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.isCompleted ? Colors.grey : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (todo.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (todo.reminderTime != null)
                          Chip(
                            label: Text(
                              _formatTime(todo.reminderTime!),
                              style: const TextStyle(fontSize: 12),
                            ),
                            avatar: isOverdue
                                ? const Icon(Icons.warning,
                                    size: 14, color: Colors.white)
                                : const Icon(Icons.access_time,
                                    size: 14, color: Colors.white),
                            backgroundColor: isOverdue
                                ? Colors.red
                                : theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isOverdue
                                  ? Colors.white
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        Chip(
                          label: Text(
                            todo.priority.displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: todo.priority.color.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: todo.priority.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (todo.reminderEnabled)
                          Chip(
                            label: const Text(
                              '已开启提醒',
                              style: TextStyle(fontSize: 12),
                            ),
                            avatar: const Icon(Icons.notifications_active,
                                size: 14, color: Colors.white),
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
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
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todoDate = DateTime(time.year, time.month, time.day);

    if (todoDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
