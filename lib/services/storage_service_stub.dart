// Stub file for conditional import
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../models/todo_item.dart';

import 'storage_service.dart' as mobile;
import 'storage_service_web.dart' as web;

// 使用条件导入的StorageService
class StorageService {
  static Future<void> initialize() =>
      kIsWeb ? web.StorageServiceWeb.initialize() : mobile.StorageService.initialize();

  static Future<User?> getCurrentUser() =>
      kIsWeb ? web.StorageServiceWeb.getCurrentUser() : mobile.StorageService.getCurrentUser();

  static Future<User?> login(String username, String password) =>
      kIsWeb ? web.StorageServiceWeb.login(username, password) : mobile.StorageService.login(username, password);

  static Future<User?> register(String username, String password) async {
    if (kIsWeb) {
      final success = await web.StorageServiceWeb.register(username, password);
      return success ? await web.StorageServiceWeb.getUser(username) : null;
    } else {
      return await mobile.StorageService.register(username, password);
    }
  }

  static Future<bool> userExists(String username) async {
    if (kIsWeb) {
      final user = await web.StorageServiceWeb.getUser(username);
      return user != null;
    } else {
      return await mobile.StorageService.userExists(username);
    }
  }

  static Future<void> logout() =>
      kIsWeb ? web.StorageServiceWeb.logout() : mobile.StorageService.logout();

  static Future<void> addTodo(String username, TodoItem todo) =>
      kIsWeb ? web.StorageServiceWeb.addTodo(todo, username) : mobile.StorageService.addTodo(username, todo);

  static Future<List<TodoItem>> getTodos(String username) =>
      kIsWeb ? web.StorageServiceWeb.getTodos(username) : mobile.StorageService.getTodos(username);

  static Future<List<TodoItem>> getTodayTodos(String username) =>
      kIsWeb ? web.StorageServiceWeb.getTodayTodos(username) : mobile.StorageService.getTodayTodos(username);

  static Future<List<TodoItem>> getWeekTodos(String username) =>
      kIsWeb ? web.StorageServiceWeb.getWeekTodos(username) : mobile.StorageService.getWeekTodos(username);

  static Future<List<TodoItem>> getMonthTodos(String username) =>
      kIsWeb ? web.StorageServiceWeb.getMonthTodos(username) : mobile.StorageService.getMonthTodos(username);

  static Future<List<TodoItem>> searchTodos(String username, String keyword) =>
      kIsWeb ? web.StorageServiceWeb.searchTodos(username, keyword) : mobile.StorageService.searchTodos(username, keyword);

  static Future<void> updateTodo(TodoItem todo) =>
      kIsWeb ? web.StorageServiceWeb.updateTodo(todo) : mobile.StorageService.updateTodo(todo);

  static Future<void> deleteTodo(String todoId) =>
      kIsWeb ? web.StorageServiceWeb.deleteTodo(todoId) : mobile.StorageService.deleteTodo(todoId);

  static Future<void> markTodoCompleted(String todoId, bool completed) async {
    if (kIsWeb) {
      await web.StorageServiceWeb.markTodoCompleted(todoId, completed);
    } else {
      if (completed) {
        await mobile.StorageService.markTodoCompleted(todoId);
      } else {
        await mobile.StorageService.markTodoIncomplete(todoId);
      }
    }
  }
}
