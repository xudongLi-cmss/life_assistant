import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/todo_item.dart';
import '../../services/storage_service_stub.dart';
import '../todo/todo_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final VoidCallback? onTodoUpdated;

  const SearchScreen({super.key, this.onTodoUpdated});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TodoItem> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final username = context.read<UserProvider>().currentUser?.username;
    if (username == null) {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
      return;
    }

    final results = await StorageService.searchTodos(username, query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchBar(
                controller: _searchController,
                leading: const Icon(Icons.search),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _hasSearched = false;
                        });
                      },
                    ),
                ],
                hintText: '搜索待办事项...',
                onSubmitted: _performSearch,
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      _searchResults = [];
                      _hasSearched = false;
                    });
                  }
                },
              ),
            ),

            // 搜索结果
            Expanded(
              child: _buildResults(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '输入关键词搜索待办事项',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.find_in_page,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '未找到相关事项',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final todo = _searchResults[index];
        return _buildTodoCard(context, todo);
      },
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
                onTodoUpdated: () {
                  _performSearch(_searchController.text);
                  widget.onTodoUpdated?.call();
                },
              ),
            ),
          );
          _performSearch(_searchController.text);
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
                  _performSearch(_searchController.text);
                  widget.onTodoUpdated?.call();
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
                              _formatDateTime(todo.reminderTime!),
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
                        if (todo.isCompleted)
                          Chip(
                            label: const Text(
                              '已完成',
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.green.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // 操作菜单
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'detail':
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TodoDetailScreen(
                            todo: todo,
                            onTodoUpdated: () {
                              _performSearch(_searchController.text);
                              widget.onTodoUpdated?.call();
                            },
                          ),
                        ),
                      );
                      _performSearch(_searchController.text);
                      break;
                    case 'delete':
                      await _showDeleteDialog(context, todo);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18),
                        SizedBox(width: 8),
                        Text('查看详情'),
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
        ),
      ),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteTodo(todo.id);
      if (context.mounted) {
        _performSearch(_searchController.text);
        widget.onTodoUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('事项已删除')),
        );
      }
    }
  }
}
