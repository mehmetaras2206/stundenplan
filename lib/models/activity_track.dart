import 'package:flutter/material.dart';

class ActivityTrack {
  final String id;
  final String activityName;
  final String? scheduleItemId; // Link to schedule item if tracking a course
  final String? categoryId;
  final String? predefinedActivityId; // Link to predefined activity
  final DateTime startTime;
  final DateTime? endTime;
  final bool isRunning;
  final bool isPaused;
  final int pausedDuration; // Total paused time in seconds
  final DateTime? pauseStartTime; // When current pause started
  final DateTime? weekStartDate; // Monday of the week this activity belongs to
  final Color? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityTrack({
    required this.id,
    required this.activityName,
    this.scheduleItemId,
    this.categoryId,
    this.predefinedActivityId,
    required this.startTime,
    this.endTime,
    required this.isRunning,
    this.isPaused = false,
    this.pausedDuration = 0,
    this.pauseStartTime,
    this.weekStartDate,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    final totalDuration = end.difference(startTime);

    // Subtract total paused time
    int totalPausedSeconds = pausedDuration;

    // Only add current pause if activity is still running (endTime is null)
    if (endTime == null && isPaused && pauseStartTime != null) {
      totalPausedSeconds += DateTime.now().difference(pauseStartTime!).inSeconds;
    }

    return totalDuration - Duration(seconds: totalPausedSeconds);
  }

  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    // Show seconds only when duration is less than 1 minute
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  factory ActivityTrack.fromJson(Map<String, dynamic> json) {
    return ActivityTrack(
      id: json['id'],
      activityName: json['activity_name'],
      scheduleItemId: json['schedule_item_id'],
      categoryId: json['category_id'],
      predefinedActivityId: json['predefined_activity_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      isRunning: json['is_running'] == 1,
      isPaused: json['is_paused'] == 1,
      pausedDuration: json['paused_duration'] ?? 0,
      pauseStartTime: json['pause_start_time'] != null
          ? DateTime.parse(json['pause_start_time'])
          : null,
      weekStartDate: json['week_start_date'] != null
          ? DateTime.parse(json['week_start_date'])
          : null,
      color: json['color'] != null ? Color(json['color']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_name': activityName,
      'schedule_item_id': scheduleItemId,
      'category_id': categoryId,
      'predefined_activity_id': predefinedActivityId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_running': isRunning ? 1 : 0,
      'is_paused': isPaused ? 1 : 0,
      'paused_duration': pausedDuration,
      'pause_start_time': pauseStartTime?.toIso8601String(),
      'week_start_date': weekStartDate?.toIso8601String(),
      'color': color?.toARGB32(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ActivityTrack copyWith({
    String? id,
    String? activityName,
    String? scheduleItemId,
    String? categoryId,
    String? predefinedActivityId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isRunning,
    bool? isPaused,
    int? pausedDuration,
    DateTime? pauseStartTime,
    bool clearPauseStartTime = false,
    DateTime? weekStartDate,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityTrack(
      id: id ?? this.id,
      activityName: activityName ?? this.activityName,
      scheduleItemId: scheduleItemId ?? this.scheduleItemId,
      categoryId: categoryId ?? this.categoryId,
      predefinedActivityId: predefinedActivityId ?? this.predefinedActivityId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      pauseStartTime: clearPauseStartTime ? null : (pauseStartTime ?? this.pauseStartTime),
      weekStartDate: weekStartDate ?? this.weekStartDate,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
