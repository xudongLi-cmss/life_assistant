import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/todo_item.dart';
import '../../services/storage_service_stub.dart';
import '../../services/notification_service.dart';

class TodoEditScreen extends StatefulWidget {
  final TodoItem todo;
  final VoidCallback? onTodoUpdated;

  const TodoEditScreen({
    super.key,
    required this.todo,
    this.onTodoUpdated,
  });

  @override
  State<TodoEditScreen> createState() => _TodoEditScreenState();
}

class _TodoEditScreenState extends State<TodoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _reminderContentController;

  late DateTime? _reminderTime;
  late bool _reminderEnabled;
  late ReminderMethod _reminderMethod;
  late TodoPriority _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController =
        TextEditingController(text: widget.todo.description ?? '');
    _reminderContentController =
        TextEditingController(text: widget.todo.reminderContent ?? '');

    _reminderTime = widget.todo.reminderTime;
    _reminderEnabled = widget.todo.reminderEnabled;
    _reminderMethod = widget.todo.reminderMethod;
    _priority = widget.todo.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reminderContentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedTodo = widget.todo.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      reminderTime: _reminderTime,
      reminderEnabled: _reminderEnabled,
      reminderMethod: _reminderMethod,
      reminderContent: _reminderContentController.text.trim().isEmpty
          ? null
          : _reminderContentController.text.trim(),
      priority: _priority,
    );

    await StorageService.updateTodo(updatedTodo);

    if (_reminderEnabled && _reminderTime != null) {
      await NotificationService.scheduleTodoReminder(updatedTodo);
    } else {
      await NotificationService.cancelTodoReminder(updatedTodo.id);
    }

    if (mounted) {
      Navigator.of(context).pop();
      widget.onTodoUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('事项已更新')),
      );
    }
  }

  Future<void> _selectReminderTime() async {
    final now = DateTime.now();
    final initialDate = _reminderTime ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null || !mounted) return;

    setState(() {
      _reminderTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑事项'),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '请输入事项标题',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入事项标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 描述
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '请输入事项描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 提醒时间
            Card(
              child: ListTile(
                title: const Text('提醒时间'),
                subtitle: Text(
                  _reminderTime == null
                      ? '未设置'
                      : '${_reminderTime!.year}-${_reminderTime!.month.toString().padLeft(2, '0')}-${_reminderTime!.day.toString().padLeft(2, '0')} ${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_reminderTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _reminderTime = null;
                          });
                        },
                      ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
                onTap: _selectReminderTime,
              ),
            ),
            const SizedBox(height: 16),

            // 提醒开关
            SwitchListTile(
              title: const Text('启用提醒'),
              subtitle: const Text('在指定时间提醒我'),
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() {
                  _reminderEnabled = value;
                });
              },
            ),
            const SizedBox(height: 8),

            // 提醒方式
            if (_reminderEnabled)
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '提醒方式',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    RadioListTile<ReminderMethod>(
                      title: const Text('通知'),
                      value: ReminderMethod.notification,
                      groupValue: _reminderMethod,
                      onChanged: (value) {
                        setState(() {
                          _reminderMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<ReminderMethod>(
                      title: const Text('声音'),
                      value: ReminderMethod.sound,
                      groupValue: _reminderMethod,
                      onChanged: (value) {
                        setState(() {
                          _reminderMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<ReminderMethod>(
                      title: const Text('震动'),
                      value: ReminderMethod.vibration,
                      groupValue: _reminderMethod,
                      onChanged: (value) {
                        setState(() {
                          _reminderMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<ReminderMethod>(
                      title: const Text('声音+震动'),
                      value: ReminderMethod.soundAndVibration,
                      groupValue: _reminderMethod,
                      onChanged: (value) {
                        setState(() {
                          _reminderMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            if (_reminderEnabled) const SizedBox(height: 16),

            // 提醒内容
            if (_reminderEnabled)
              TextFormField(
                controller: _reminderContentController,
                decoration: const InputDecoration(
                  labelText: '提醒内容（可选）',
                  hintText: '自定义提醒内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            if (_reminderEnabled) const SizedBox(height: 16),

            // 优先级
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '优先级',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  RadioListTile<TodoPriority>(
                    title: const Text('低'),
                    value: TodoPriority.low,
                    groupValue: _priority,
                    onChanged: (value) {
                      setState(() {
                        _priority = value!;
                      });
                    },
                  ),
                  RadioListTile<TodoPriority>(
                    title: const Text('中'),
                    value: TodoPriority.medium,
                    groupValue: _priority,
                    onChanged: (value) {
                      setState(() {
                        _priority = value!;
                      });
                    },
                  ),
                  RadioListTile<TodoPriority>(
                    title: const Text('高'),
                    value: TodoPriority.high,
                    groupValue: _priority,
                    onChanged: (value) {
                      setState(() {
                        _priority = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
