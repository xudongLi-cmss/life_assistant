import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/storage_service_stub.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const SettingsScreen({super.key, this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pendingNotifications =
        await NotificationService.getPendingNotifications();
    setState(() {
      _notificationCount = pendingNotifications.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // 用户信息卡片
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            color:
                                theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '欢迎使用生活助理',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 通知设置
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '通知设置',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: SwitchListTile(
                  title: const Text('启用通知'),
                  subtitle: const Text('接收待办事项提醒通知'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    // 这里可以保存设置
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  title: const Text('活跃通知'),
                  subtitle: Text('共 $_notificationCount 个待发送通知'),
                  leading: const Icon(Icons.notifications_active),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey[400]),
                  onTap: () async {
                    await _loadSettings();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('当前有 $_notificationCount 个待发送通知'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),

            // 数据管理
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '数据管理',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  title: const Text('清空已完成事项'),
                  subtitle: const Text('删除所有已完成的待办事项'),
                  leading: const Icon(Icons.cleaning_services),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey[400]),
                  onTap: () => _showClearCompletedDialog(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  title: const Text('清空所有事项'),
                  subtitle: const Text('删除所有待办事项（谨慎操作）'),
                  leading: const Icon(Icons.delete_sweep,
                      color: Colors.red),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey[400]),
                  onTap: () => _showClearAllDialog(context),
                ),
              ),
            ),

            // 关于
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '关于',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('版本'),
                      subtitle: const Text('V1.0.0'),
                      leading: const Icon(Icons.info_outline),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('关于应用'),
                      subtitle: const Text('生活助理 - 智能事项提醒助手'),
                      leading: const Icon(Icons.apps),
                      trailing:
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),
            ),

            // 退出登录
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.tonal(
                onPressed: () => _showLogoutDialog(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('退出登录'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearCompletedDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空已完成事项'),
        content: const Text('确定要清空所有已完成的待办事项吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // TODO: 实现清空已完成事项的逻辑
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('功能开发中')),
      );
    }
  }

  Future<void> _showClearAllDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有事项'),
        content: const Text('确定要清空所有待办事项吗？此操作不可撤销，请谨慎操作。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空全部'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final username = context.read<UserProvider>().currentUser?.username;
      if (username != null) {
        final todos = await StorageService.getTodos(username);
        for (final todo in todos) {
          await StorageService.deleteTodo(todo.id);
          await NotificationService.cancelTodoReminder(todo.id);
        }
        await _loadSettings();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('所有事项已清空')),
          );
        }
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<UserProvider>().logout();
    }
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于生活助理'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('生活助理'),
            SizedBox(height: 8),
            Text('版本：V1.0.0'),
            SizedBox(height: 16),
            Text(
              '一款智能的待办事项提醒应用，帮助您高效管理时间和任务。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '功能特点：\n'
              '• 智能事项解析\n'
              '• 多维度规划查看\n'
              '• 灵活的提醒设置\n'
              '• 本地数据存储',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
