import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/todo_item.dart';
import '../../services/storage_service_stub.dart';
import '../../services/notification_service.dart';
import 'todo_edit_screen.dart';

class TodoDetailScreen extends StatefulWidget {
  final TodoItem todo;
  final VoidCallback? onTodoUpdated;

  const TodoDetailScreen({
    super.key,
    required this.todo,
    this.onTodoUpdated,
  });

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  late TodoItem _todo;

  @override
  void initState() {
    super.initState();
    _todo = widget.todo;
  }

  Future<void> _toggleComplete() async {
    final newState = !_todo.isCompleted;
    await StorageService.markTodoCompleted(_todo.id, newState);
    setState(() {
      _todo = _todo.copyWith(
        isCompleted: newState,
        completedAt: newState ? DateTime.now() : null,
      );
    });
    widget.onTodoUpdated?.call();
  }

  Future<void> _deleteTodo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除事项'),
        content: Text('确定要删除「${_todo.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await StorageService.deleteTodo(_todo.id);
      await NotificationService.cancelTodoReminder(_todo.id);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onTodoUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('事项已删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('事项详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TodoEditScreen(
                    todo: _todo,
                    onTodoUpdated: () async {
                      // 重新加载数据
                      final username =
                          context.read<UserProvider>().currentUser?.username;
                      if (username == null) return;

                      final todos = await StorageService.getTodos(username);
                      final updatedTodo =
                          todos.firstWhere((t) => t.id == _todo.id);

                      setState(() {
                        _todo = updatedTodo;
                      });
                      widget.onTodoUpdated?.call();
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTodo,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 完成状态卡片
          Card(
            color: _todo.isCompleted
                ? Colors.green.withOpacity(0.1)
                : theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(
                _todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: _todo.isCompleted ? Colors.green : theme.colorScheme.primary,
              ),
              title: Text(
                _todo.isCompleted ? '已完成' : '未完成',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _todo.isCompleted
                      ? Colors.green
                      : theme.colorScheme.primary,
                ),
              ),
              trailing: FilledButton.tonal(
                onPressed: _toggleComplete,
                child: Text(_todo.isCompleted ? '标记为未完成' : '标记为完成'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 标题
          Text(
            _todo.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: _todo.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 8),

          // 描述
          if (_todo.description != null) ...[
            Text(
              _todo.description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 时间信息
          if (_todo.reminderTime != null)
            Card(
              child: ListTile(
                leading: Icon(
                  _todo.isOverdue && !_todo.isCompleted
                      ? Icons.warning
                      : Icons.access_time,
                  color: _todo.isOverdue && !_todo.isCompleted
                      ? Colors.red
                      : theme.colorScheme.primary,
                ),
                title: Text(
                  _todo.isOverdue && !_todo.isCompleted ? '已逾期' : '提醒时间',
                  style: TextStyle(
                    color: _todo.isOverdue && !_todo.isCompleted
                        ? Colors.red
                        : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${_todo.reminderTime!.year}-${_todo.reminderTime!.month.toString().padLeft(2, '0')}-${_todo.reminderTime!.day.toString().padLeft(2, '0')} ${_todo.reminderTime!.hour.toString().padLeft(2, '0')}:${_todo.reminderTime!.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          if (_todo.reminderTime != null) const SizedBox(height: 8),

          // 创建时间
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('创建时间'),
              subtitle: Text(
                '${_todo.createdAt.year}-${_todo.createdAt.month.toString().padLeft(2, '0')}-${_todo.createdAt.day.toString().padLeft(2, '0')} ${_todo.createdAt.hour.toString().padLeft(2, '0')}:${_todo.createdAt.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 优先级
          Card(
            child: ListTile(
              leading: Icon(
                Icons.flag,
                color: _todo.priority.color,
              ),
              title: const Text('优先级'),
              subtitle: Text(_todo.priority.displayName),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _todo.priority.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _todo.priority.displayName,
                  style: TextStyle(
                    color: _todo.priority.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 提醒设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _todo.reminderEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: _todo.reminderEnabled
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '提醒设置',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: _todo.reminderEnabled,
                        onChanged: (value) async {
                          setState(() {
                            _todo = _todo.copyWith(reminderEnabled: value);
                          });
                          await StorageService.updateTodo(_todo);

                          if (value && _todo.reminderTime != null) {
                            await NotificationService.scheduleTodoReminder(_todo);
                          } else {
                            await NotificationService.cancelTodoReminder(_todo.id);
                          }
                          widget.onTodoUpdated?.call();
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(_todo.reminderEnabled ? '已开启' : '已关闭'),
                    ],
                  ),
                  if (_todo.reminderEnabled) ...[
                    const SizedBox(height: 12),
                    Text(
                      '提醒方式：${_getReminderMethodText(_todo.reminderMethod)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_todo.reminderContent != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '提醒内容：${_todo.reminderContent}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getReminderMethodText(ReminderMethod method) {
    switch (method) {
      case ReminderMethod.notification:
        return '通知';
      case ReminderMethod.sound:
        return '声音';
      case ReminderMethod.vibration:
        return '震动';
      case ReminderMethod.soundAndVibration:
        return '声音+震动';
    }
  }
}
