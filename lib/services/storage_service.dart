import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/todo_item.dart';
import 'dart:convert';

class StorageService {
  static Database? _database;
  static SharedPreferences? _prefs;

  static const String _dbName = 'life_assistant.db';
  static const int _dbVersion = 1;

  // 表名
  static const String tableUsers = 'users';
  static const String tableTodos = 'todos';

  // 初始化数据库
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 创建用户表
    await db.execute('''
      CREATE TABLE $tableUsers (
        username TEXT PRIMARY KEY,
        password TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 创建待办事项表
    await db.execute('''
      CREATE TABLE $tableTodos (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        reminderTime TEXT,
        completedAt TEXT,
        isCompleted INTEGER DEFAULT 0,
        reminderEnabled INTEGER DEFAULT 1,
        reminderMethod INTEGER DEFAULT 0,
        reminderContent TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        priority INTEGER DEFAULT 1,
        FOREIGN KEY (username) REFERENCES $tableUsers (username) ON DELETE CASCADE
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_todos_username ON $tableTodos(username)
    ''');
    await db.execute('''
      CREATE INDEX idx_todos_reminderTime ON $tableTodos(reminderTime)
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级逻辑
  }

  // 获取当前登录用户
  static Future<User?> getCurrentUser() async {
    final username = _prefs?.getString('currentUser');
    if (username == null) return null;

    final List<Map<String, dynamic>> maps = await _database!.query(
      tableUsers,
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // 登录
  static Future<User?> login(String username, String password) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      tableUsers,
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isEmpty) return null;

    final user = User.fromMap(maps.first);
    await _prefs?.setString('currentUser', username);
    return user;
  }

  // 注册
  static Future<User?> register(String username, String password) async {
    try {
      final user = User(username: username, password: password);
      await _database!.insert(tableUsers, user.toMap());
      await _prefs?.setString('currentUser', username);
      return user;
    } catch (e) {
      // 用户名已存在
      return null;
    }
  }

  // 检查用户名是否存在
  static Future<bool> userExists(String username) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      tableUsers,
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty;
  }

  // 登出
  static Future<void> logout() async {
    await _prefs?.remove('currentUser');
  }

  // 添加待办事项
  static Future<void> addTodo(String username, TodoItem todo) async {
    final map = todo.toMap();
    map['username'] = username;
    await _database!.insert(tableTodos, map);
  }

  // 获取用户所有待办事项
  static Future<List<TodoItem>> getTodos(String username) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      tableTodos,
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'reminderTime ASC',
    );

    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  // 获取特定时间范围的待办事项
  static Future<List<TodoItem>> getTodosInDateRange(
    String username,
    DateTime start,
    DateTime end,
  ) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      tableTodos,
      where: 'username = ? AND reminderTime >= ? AND reminderTime <= ?',
      whereArgs: [username, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'reminderTime ASC',
    );

    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  // 获取今日待办事项
  static Future<List<TodoItem>> getTodayTodos(String username) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    return getTodosInDateRange(username, start, end);
  }

  // 获取本周待办事项
  static Future<List<TodoItem>> getWeekTodos(String username) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));

    return getTodosInDateRange(username, start, end);
  }

  // 获取本月待办事项
  static Future<List<TodoItem>> getMonthTodos(String username) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));

    return getTodosInDateRange(username, start, end);
  }

  // 搜索待办事项
  static Future<List<TodoItem>> searchTodos(String username, String query) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      tableTodos,
      where: 'username = ? AND (title LIKE ? OR description LIKE ?)',
      whereArgs: [username, '%$query%', '%$query%'],
      orderBy: 'reminderTime ASC',
    );

    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  // 更新待办事项
  static Future<void> updateTodo(TodoItem todo) async {
    await _database!.update(
      tableTodos,
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  // 删除待办事项
  static Future<void> deleteTodo(String todoId) async {
    await _database!.delete(
      tableTodos,
      where: 'id = ?',
      whereArgs: [todoId],
    );
  }

  // 标记待办事项为完成
  static Future<void> markTodoCompleted(String todoId) async {
    await _database!.execute('''
      UPDATE $tableTodos
      SET isCompleted = 1, completedAt = ?, updatedAt = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), DateTime.now().toIso8601String(), todoId]);
  }

  // 标记待办事项为未完成
  static Future<void> markTodoIncomplete(String todoId) async {
    await _database!.execute('''
      UPDATE $tableTodos
      SET isCompleted = 0, completedAt = NULL, updatedAt = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), todoId]);
  }

  // 获取待办事项统计
  static Future<Map<String, int>> getTodoStats(String username) async {
    final todos = await getTodos(username);

    return {
      'total': todos.length,
      'completed': todos.where((t) => t.isCompleted).length,
      'pending': todos.where((t) => !t.isCompleted).length,
      'overdue': todos.where((t) => t.isOverdue && !t.isCompleted).length,
      'today': todos.where((t) => t.isToday && !t.isCompleted).length,
    };
  }
}
