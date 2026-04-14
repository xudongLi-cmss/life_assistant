import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/todo_item.dart';
import 'dart:convert';

/// Web平台存储服务 - 使用SharedPreferences + JSON
/// 在Web上，SharedPreferences使用localStorage
class StorageServiceWeb {
  static SharedPreferences? _prefs;

  // 存储键
  static const String _keyUsers = 'users';
  static const String _keyTodos = 'todos';
  static const String _keyCurrentUser = 'currentUser';

  // 初始化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 获取当前登录用户
  static Future<User?> getCurrentUser() async {
    final username = _prefs?.getString(_keyCurrentUser);
    if (username == null) return null;
    return await getUser(username);
  }

  // 登录
  static Future<User?> login(String username, String password) async {
    final user = await getUser(username);
    if (user == null || user.password != password) return null;

    await _prefs?.setString(_keyCurrentUser, username);
    return user;
  }

  // 注册
  static Future<bool> register(String username, String password) async {
    final existingUser = await getUser(username);
    if (existingUser != null) return false; // 用户已存在

    final newUser = User(
      username: username,
      password: password,
    );

    final users = await _getUsers();
    users[username] = newUser.toMap();
    await _saveUsers(users);

    // 自动登录
    await _prefs?.setString(_keyCurrentUser, username);
    return true;
  }

  // 登出
  static Future<void> logout() async {
    await _prefs?.remove(_keyCurrentUser);
  }

  // 获取用户
  static Future<User?> getUser(String username) async {
    final users = await _getUsers();
    final userMap = users[username];
    if (userMap == null) return null;
    return User.fromMap(userMap);
  }

  // 添加待办事项
  static Future<void> addTodo(TodoItem todo, String username) async {
    final todos = await _getTodos();
    todos[todo.id] = {
      ...todo.toMap(),
      'username': username,
    };
    await _saveTodos(todos);
  }

  // 获取所有待办事项
  static Future<List<TodoItem>> getTodos(String username) async {
    final todos = await _getTodos();
    return todos.values
        .where((todo) => todo['username'] == username)
        .map((map) => TodoItem.fromMap(map))
        .toList();
  }

  // 获取今日待办
  static Future<List<TodoItem>> getTodayTodos(String username) async {
    final todos = await getTodos(username);
    return todos.where((todo) => todo.isToday).toList();
  }

  // 获取本周待办
  static Future<List<TodoItem>> getWeekTodos(String username) async {
    final todos = await getTodos(username);
    return todos.where((todo) => todo.isThisWeek).toList();
  }

  // 获取本月待办
  static Future<List<TodoItem>> getMonthTodos(String username) async {
    final todos = await getTodos(username);
    return todos.where((todo) => todo.isThisMonth).toList();
  }

  // 搜索待办事项
  static Future<List<TodoItem>> searchTodos(String username, String keyword) async {
    final todos = await getTodos(username);
    final lowerKeyword = keyword.toLowerCase();
    return todos.where((todo) =>
      todo.title.toLowerCase().contains(lowerKeyword) ||
      (todo.description?.toLowerCase().contains(lowerKeyword) ?? false)
    ).toList();
  }

  // 更新待办事项
  static Future<void> updateTodo(TodoItem todo) async {
    final todos = await _getTodos();
    if (todos.containsKey(todo.id)) {
      todos[todo.id] = {
        ...todo.toMap(),
        'username': todos[todo.id]['username'],
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await _saveTodos(todos);
    }
  }

  // 删除待办事项
  static Future<void> deleteTodo(String todoId) async {
    final todos = await _getTodos();
    todos.remove(todoId);
    await _saveTodos(todos);
  }

  // 标记待办事项为完成
  static Future<void> markTodoCompleted(String todoId, bool completed) async {
    final todos = await _getTodos();
    if (todos.containsKey(todoId)) {
      todos[todoId]['isCompleted'] = completed ? 1 : 0;
      todos[todoId]['completedAt'] = completed ? DateTime.now().toIso8601String() : null;
      todos[todoId]['updatedAt'] = DateTime.now().toIso8601String();
      await _saveTodos(todos);
    }
  }

  // 私有方法：获取所有用户
  static Future<Map<String, dynamic>> _getUsers() async {
    final json = _prefs?.getString(_keyUsers) ?? '{}';
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (e) {
      return {};
    }
  }

  // 私有方法：保存所有用户
  static Future<void> _saveUsers(Map<String, dynamic> users) async {
    await _prefs?.setString(_keyUsers, jsonEncode(users));
  }

  // 私有方法：获取所有待办事项
  static Future<Map<String, dynamic>> _getTodos() async {
    final json = _prefs?.getString(_keyTodos) ?? '{}';
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (e) {
      return {};
    }
  }

  // 私有方法：保存所有待办事项
  static Future<void> _saveTodos(Map<String, dynamic> todos) async {
    await _prefs?.setString(_keyTodos, jsonEncode(todos));
  }

  // 清空所有数据（用于测试）
  static Future<void> clearAll() async {
    await _prefs?.remove(_keyUsers);
    await _prefs?.remove(_keyTodos);
    await _prefs?.remove(_keyCurrentUser);
  }
}
