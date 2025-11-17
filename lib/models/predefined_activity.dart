import 'package:flutter/material.dart';

class PredefinedActivity {
  final String id;
  final String name;
  final Color? color;
  final IconData? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  PredefinedActivity({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PredefinedActivity.fromJson(Map<String, dynamic> json) {
    return PredefinedActivity(
      id: json['id'],
      name: json['name'],
      color: json['color'] != null ? Color(json['color']) : null,
      icon: json['icon_codepoint'] != null
          ? IconData(json['icon_codepoint'], fontFamily: 'MaterialIcons')
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color?.toARGB32(),
      'icon_codepoint': icon?.codePoint,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PredefinedActivity copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PredefinedActivity(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
