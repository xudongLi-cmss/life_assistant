import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_assistant/models/todo_item.dart';
import 'package:life_assistant/models/user.dart';
import 'package:life_assistant/services/local_nlp_parser.dart';

void main() {
  group('TodoItem Tests', () {
    test('TodoItem should create with required fields', () {
      final todo = TodoItem(
        id: '1',
        title: 'Test Todo',
      );

      expect(todo.id, '1');
      expect(todo.title, 'Test Todo');
      expect(todo.isCompleted, false);
      expect(todo.priority, TodoPriority.medium);
    });

    test('TodoItem should convert to map and back', () {
      final todo = TodoItem(
        id: '1',
        title: 'Test Todo',
        description: 'Test Description',
        reminderTime: DateTime(2024, 1, 1, 12, 0),
        isCompleted: false,
        priority: TodoPriority.high,
      );

      final map = todo.toMap();
      final fromMap = TodoItem.fromMap(map);

      expect(fromMap.id, todo.id);
      expect(fromMap.title, todo.title);
      expect(fromMap.description, todo.description);
      expect(fromMap.priority, todo.priority);
    });

    test('TodoItem should detect overdue correctly', () {
      final pastTodo = TodoItem(
        id: '1',
        title: 'Past Todo',
        reminderTime: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final futureTodo = TodoItem(
        id: '2',
        title: 'Future Todo',
        reminderTime: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(pastTodo.isOverdue, true);
      expect(futureTodo.isOverdue, false);
    });

    test('TodoItem should detect today correctly', () {
      final todayTodo = TodoItem(
        id: '1',
        title: 'Today Todo',
        reminderTime: DateTime.now(),
      );

      final yesterdayTodo = TodoItem(
        id: '2',
        title: 'Yesterday Todo',
        reminderTime: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(todayTodo.isToday, true);
      expect(yesterdayTodo.isToday, false);
    });
  });

  group('User Tests', () {
    test('User should create with required fields', () {
      final user = User(
        username: 'testuser',
        password: 'password123',
      );

      expect(user.username, 'testuser');
      expect(user.password, 'password123');
      expect(user.createdAt, isNotNull);
    });

    test('User should convert to map and back', () {
      final user = User(
        username: 'testuser',
        password: 'password123',
      );

      final map = user.toMap();
      final fromMap = User.fromMap(map);

      expect(fromMap.username, user.username);
      expect(fromMap.password, user.password);
    });
  });

  group('LocalNLPParser Tests', () {
    test('Should parse simple todo', () async {
      final todos = await LocalNlpParser.parse('今天下午3点开会');

      expect(todos.length, greaterThan(0));
      expect(todos.first.title, contains('开会'));
      expect(todos.first.reminderTime, isNotNull);
    });

    test('Should parse multiple todos', () async {
      final input = '今天下午3点开会，明天早上8点锻炼身体';
      final todos = await LocalNlpParser.parse(input);

      expect(todos.length, greaterThan(1));
    });

    test('Should infer priority from keywords', () async {
      final urgentTodo = (await LocalNlpParser.parse('重要紧急！马上完成报告'))
          .first;
      final normalTodo = (await LocalNlpParser.parse('有空整理一下文件')).first;

      expect(urgentTodo.priority, TodoPriority.high);
      expect(normalTodo.priority, TodoPriority.low);
    });

    test('Should parse relative dates', () async {
      final todayTodos = await LocalNlpParser.parse('今天下午3点开会');
      final tomorrowTodos = await LocalNlpParser.parse('明天早上8点锻炼');

      expect(todayTodos.first.reminderTime, isNotNull);
      expect(tomorrowTodos.first.reminderTime, isNotNull);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      expect(todayTodos.first.reminderTime!.day, equals(today.day));
      expect(tomorrowTodos.first.reminderTime!.day, equals(tomorrow.day));
    });
  });

  group('TodoPriority Tests', () {
    test('Priority should have correct display names', () {
      expect(TodoPriority.low.displayName, '低');
      expect(TodoPriority.medium.displayName, '中');
      expect(TodoPriority.high.displayName, '高');
    });

    test('Priority should have correct colors', () {
      expect(TodoPriority.low.color, const Color(0xFF4CAF50));
      expect(TodoPriority.medium.color, const Color(0xFFFF9800));
      expect(TodoPriority.high.color, const Color(0xFFF44336));
    });
  });
}
