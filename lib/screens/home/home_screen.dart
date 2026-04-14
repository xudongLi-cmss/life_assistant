import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/todo_item.dart';
import '../../services/storage_service_stub.dart';
import '../../services/notification_service.dart';
import 'today_plan_screen.dart';
import 'week_plan_screen.dart';
import 'month_plan_screen.dart';
import '../search/search_screen.dart';
import '../todo/todo_add_screen.dart';
import '../settings/settings_screen.dart';
import '../input/input_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<TodoItem> _myTodos = [];

  @override
  void initState() {
    super.initState();
    _loadMyTodos();
  }

  Future<void> _loadMyTodos() async {
    final username = context.read<UserProvider>().currentUser?.username;
    if (username == null) return;

    final todos = await StorageService.getTodos(username);
    setState(() {
      _myTodos.clear();
      _myTodos.addAll(todos);
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(context, theme, user.username),
          _buildSearchPage(context, theme),
          _buildInputPage(context, theme),
          _buildMyPage(context, theme, user.username),
          _buildSettingsPage(context, theme),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '搜索',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: '输入',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(BuildContext context, ThemeData theme, String username) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎信息
              Text(
                '你好，${username}！',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '今天也要高效哦~',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // 今日规划卡片
              _buildPlanCard(
                context,
                title: '今日规划',
                subtitle: '查看今天的待办事项',
                icon: Icons.today_outlined,
                color: const Color(0xFF2196F3),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TodayPlanScreen(),
                    ),
                  );
                  _loadMyTodos();
                },
              ),
              const SizedBox(height: 16),

              // 整周规划卡片
              _buildPlanCard(
                context,
                title: '整周规划',
                subtitle: '查看本周的待办事项',
                icon: Icons.date_range_outlined,
                color: const Color(0xFFFF9800),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WeekPlanScreen(),
                    ),
                  );
                  _loadMyTodos();
                },
              ),
              const SizedBox(height: 16),

              // 整月规划卡片
              _buildPlanCard(
                context,
                title: '整月规划',
                subtitle: '查看本月的待办事项',
                icon: Icons.calendar_month_outlined,
                color: const Color(0xFF4CAF50),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MonthPlanScreen(),
                    ),
                  );
                  _loadMyTodos();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPage(BuildContext context, ThemeData theme) {
    return SearchScreen(
      onTodoUpdated: _loadMyTodos,
    );
  }

  Widget _buildInputPage(BuildContext context, ThemeData theme) {
    return InputScreen(
      onTodosAdded: _loadMyTodos,
    );
  }

  Widget _buildMyPage(BuildContext context, ThemeData theme, String username) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        color: theme.colorScheme.onPrimaryContainer,
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
                          username,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '共 ${_myTodos.length} 个待办事项',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),

            // 待办事项列表
            Expanded(
              child: _myTodos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '还没有待办事项',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _myTodos.length,
                      itemBuilder: (context, index) {
                        final todo = _myTodos[index];
                        return _buildTodoItem(context, todo);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TodoAddScreen(
                onTodoAdded: _loadMyTodos,
              ),
            ),
          );
          _loadMyTodos();
        },
        icon: const Icon(Icons.add),
        label: const Text('添加事项'),
      ),
    );
  }

  Widget _buildTodoItem(BuildContext context, TodoItem todo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (value) async {
            final username = context.read<UserProvider>().currentUser?.username;
            if (username == null || value == null) return;

            await StorageService.markTodoCompleted(todo.id, value!);
            _loadMyTodos();
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: todo.reminderTime != null
            ? Text(
                _formatDateTime(todo.reminderTime!),
                style: TextStyle(
                  fontSize: 12,
                  color: todo.isOverdue && !todo.isCompleted
                      ? Colors.red
                      : Colors.grey[600],
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (todo.reminderEnabled)
              Icon(
                Icons.notifications_active,
                size: 16,
                color: todo.isOverdue && !todo.isCompleted
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    await Navigator.of(context).pushNamed('/todo/edit', arguments: todo);
                    _loadMyTodos();
                    break;
                  case 'delete':
                    await _showDeleteDialog(context, todo);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('编辑'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          // 导航到详情页面
          await Navigator.of(context).pushNamed('/todo/detail', arguments: todo);
          _loadMyTodos();
        },
      ),
    );
  }

  Widget _buildSettingsPage(BuildContext context, ThemeData theme) {
    return SettingsScreen(
      onLogout: () => _showLogoutDialog(context),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todoDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (todoDate == today) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (todoDate == today.add(const Duration(days: 1))) {
      return '明天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, TodoItem todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除事项'),
        content: Text('确定要删除「${todo.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteTodo(todo.id);
      await NotificationService.cancelTodoReminder(todo.id);
      _loadMyTodos();
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
}
