import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final String? icon;
  final double? weeklyGoalHours; // Weekly time goal in hours
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    this.weeklyGoalHours,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      color: Color(int.parse(json['color'].replaceFirst('#', '0xFF'))),
      icon: json['icon'],
      weeklyGoalHours: json['weekly_goal_hours'] != null
          ? (json['weekly_goal_hours'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'icon': icon,
      'weekly_goal_hours': weeklyGoalHours,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    Color? color,
    String? icon,
    double? weeklyGoalHours,
    bool clearWeeklyGoal = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      weeklyGoalHours: clearWeeklyGoal ? null : (weeklyGoalHours ?? this.weeklyGoalHours),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
