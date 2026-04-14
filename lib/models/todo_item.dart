import 'package:flutter/material.dart';

class TodoItem {
  final String id;
  String title;
  String? description;
  DateTime? reminderTime;
  DateTime? completedAt;
  bool isCompleted;
  bool reminderEnabled;
  ReminderMethod reminderMethod;
  String? reminderContent;
  DateTime createdAt;
  DateTime? updatedAt;
  TodoPriority priority;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.reminderTime,
    this.completedAt,
    this.isCompleted = false,
    this.reminderEnabled = true,
    this.reminderMethod = ReminderMethod.notification,
    this.reminderContent,
    DateTime? createdAt,
    this.updatedAt,
    this.priority = TodoPriority.medium,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reminderTime': reminderTime?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderMethod': reminderMethod.index,
      'reminderContent': reminderContent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'priority': priority.index,
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      reminderTime: map['reminderTime'] != null
          ? DateTime.parse(map['reminderTime'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      isCompleted: (map['isCompleted'] as int) == 1,
      reminderEnabled: (map['reminderEnabled'] as int) == 1,
      reminderMethod: ReminderMethod.values[map['reminderMethod'] as int],
      reminderContent: map['reminderContent'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      priority: TodoPriority.values[map['priority'] as int],
    );
  }

  TodoItem copyWith({
    String? title,
    String? description,
    DateTime? reminderTime,
    DateTime? completedAt,
    bool? isCompleted,
    bool? reminderEnabled,
    ReminderMethod? reminderMethod,
    String? reminderContent,
    DateTime? updatedAt,
    TodoPriority? priority,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMethod: reminderMethod ?? this.reminderMethod,
      reminderContent: reminderContent ?? this.reminderContent,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      priority: priority ?? this.priority,
    );
  }

  bool get isOverdue {
    if (reminderTime == null || isCompleted) return false;
    return DateTime.now().isAfter(reminderTime!);
  }

  bool get isToday {
    if (reminderTime == null) return false;
    final now = DateTime.now();
    return reminderTime!.year == now.year &&
           reminderTime!.month == now.month &&
           reminderTime!.day == now.day;
  }

  bool get isThisWeek {
    if (reminderTime == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return !reminderTime!.isBefore(weekStart) &&
           !reminderTime!.isAfter(weekEnd);
  }

  bool get isThisMonth {
    if (reminderTime == null) return false;
    final now = DateTime.now();
    return reminderTime!.year == now.year &&
           reminderTime!.month == now.month;
  }
}

enum ReminderMethod {
  notification,
  sound,
  vibration,
  soundAndVibration,
}

enum TodoPriority {
  low,
  medium,
  high,
}

extension TodoPriorityExtension on TodoPriority {
  String get displayName {
    switch (this) {
      case TodoPriority.low:
        return '低';
      case TodoPriority.medium:
        return '中';
      case TodoPriority.high:
        return '高';
    }
  }

  Color get color {
    switch (this) {
      case TodoPriority.low:
        return const Color(0xFF4CAF50);
      case TodoPriority.medium:
        return const Color(0xFFFF9800);
      case TodoPriority.high:
        return const Color(0xFFF44336);
    }
  }
}
