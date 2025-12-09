import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final String? eventType;  // Vorlesung, Übung, Hausaufgaben, etc.
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;
  final String? recurrenceRule;
  final List<int> notificationMinutesBefore;
  final Color? color;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleItem({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.eventType,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.isRecurring = false,
    this.recurrenceRule,
    this.notificationMinutesBefore = const [],
    this.color,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      title: json['title'],
      eventType: json['event_type'],
      description: json['description'],
      location: json['location'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      isRecurring: json['is_recurring'] ?? false,
      recurrenceRule: json['recurrence_rule'],
      notificationMinutesBefore:
          (json['notification_minutes_before'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              [],
      color: json['color'] != null
          ? Color(int.parse(json['color'].replaceFirst('#', '0xFF')))
          : null,
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'event_type': eventType,
      'description': description,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'notification_minutes_before': notificationMinutesBefore,
      'color': color != null
          ? '#${color!.toARGB32().toRadixString(16).substring(2).toUpperCase()}'
          : null,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ScheduleItem copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? title,
    String? eventType,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    bool? isRecurring,
    String? recurrenceRule,
    List<int>? notificationMinutesBefore,
    Color? color,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      notificationMinutesBefore:
          notificationMinutesBefore ?? this.notificationMinutesBefore,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Duration get duration => endTime.difference(startTime);

  bool isOnDate(DateTime date) {
    // Normalize dates to compare only year, month, day
    final itemDate = DateTime(startTime.year, startTime.month, startTime.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    // Check if it's the original date
    if (itemDate.isAtSameMomentAs(checkDate)) {
      return true;
    }

    // If not recurring, only show on original date
    if (!isRecurring || recurrenceRule == null) {
      return false;
    }

    // Check if date is after the original start date
    if (checkDate.isBefore(itemDate)) {
      return false;
    }

    // Parse recurrence rule and check if date matches
    final rule = recurrenceRule!.toUpperCase();

    if (rule == 'DAILY') {
      return true; // Show every day after start date
    } else if (rule == 'WEEKLY') {
      // Show on same weekday
      final daysDifference = checkDate.difference(itemDate).inDays;
      return daysDifference % 7 == 0;
    } else if (rule == 'BIWEEKLY' || rule == 'BI-WEEKLY') {
      // Show every 2 weeks on same weekday
      final daysDifference = checkDate.difference(itemDate).inDays;
      return daysDifference % 14 == 0;
    } else if (rule == 'MONTHLY') {
      // Show on same day of month
      return startTime.day == date.day;
    } else if (rule == 'YEARLY') {
      // Show on same day and month
      return startTime.day == date.day && startTime.month == date.month;
    } else if (rule.startsWith('WEEKDAYS')) {
      // Monday to Friday only
      return checkDate.weekday >= 1 && checkDate.weekday <= 5;
    } else if (rule.startsWith('WEEKENDS')) {
      // Saturday and Sunday only
      return checkDate.weekday == 6 || checkDate.weekday == 7;
    }

    // Default: treat as non-recurring if rule not recognized
    return false;
  }
}
