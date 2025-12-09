import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/activity_track.dart';
import '../models/predefined_activity.dart';
import '../services/local_database_service.dart';
import '../services/foreground_service.dart';

class ActivityProvider extends ChangeNotifier {
  final LocalDatabaseService _databaseService = LocalDatabaseService();

  List<ActivityTrack> _activityTracks = [];
  List<PredefinedActivity> _predefinedActivities = [];
  ActivityTrack? _runningTrack;
  Timer? _updateTimer;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _currentWeekStart;

  List<ActivityTrack> get activityTracks => _activityTracks;
  List<PredefinedActivity> get predefinedActivities => _predefinedActivities;
  ActivityTrack? get runningTrack => _runningTrack;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasRunningTrack => _runningTrack != null;
  DateTime get currentWeekStart => _currentWeekStart ?? _calculateWeekStart(DateTime.now());

  ActivityProvider() {
    loadData();
    _startUpdateTimer();
    _setupForegroundTaskHandler();
  }

  void _setupForegroundTaskHandler() {
    if (Platform.isAndroid) {
      FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    }
  }

  void _onReceiveTaskData(dynamic data) {
    if (data is Map && data['action'] != null) {
      final action = data['action'] as String;
      switch (action) {
        case 'pause':
          pauseActivity();
          break;
        case 'resume':
          resumeActivity();
          break;
        case 'stop':
          stopActivity();
          break;
      }
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    if (Platform.isAndroid) {
      FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    }
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_runningTrack != null) {
        notifyListeners(); // Update UI every second for running timer
      }
    });
  }

  /// Calculate the start of the week (Monday) for a given date
  DateTime _calculateWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final monday = date.subtract(Duration(days: weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentWeekStart = _calculateWeekStart(DateTime.now());

      // Load only activities from current week
      _activityTracks = await _databaseService.getActivityTracksForWeek(_currentWeekStart!);
      _runningTrack = await _databaseService.getRunningActivityTrack();

      // Load predefined activities
      _predefinedActivities = await _databaseService.getPredefinedActivities();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startActivity({
    required String activityName,
    String? scheduleItemId,
    String? categoryId,
    String? predefinedActivityId,
    Color? color,
  }) async {
    try {
      // Stop any running activity first
      if (_runningTrack != null) {
        await stopActivity();
      }

      final now = DateTime.now();
      final weekStart = _calculateWeekStart(now);

      final track = ActivityTrack(
        id: const Uuid().v4(),
        activityName: activityName,
        scheduleItemId: scheduleItemId,
        categoryId: categoryId,
        predefinedActivityId: predefinedActivityId,
        startTime: now,
        weekStartDate: weekStart,
        isRunning: true,
        color: color,
        createdAt: now,
        updatedAt: now,
      );

      await _databaseService.insertActivityTrack(track);
      _runningTrack = track;
      _activityTracks.insert(0, track);

      // Start foreground service (Android only)
      if (Platform.isAndroid) {
        await ActivityForegroundService().startService(
          activityId: track.id,
          activityName: track.activityName,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> pauseActivity() async {
    if (_runningTrack == null || _runningTrack!.isPaused) return;

    try {
      final updated = _runningTrack!.copyWith(
        isPaused: true,
        pauseStartTime: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateActivityTrack(updated);
      _runningTrack = updated;

      // Update in list
      final index = _activityTracks.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _activityTracks[index] = updated;
      }

      // Update foreground service (Android only)
      if (Platform.isAndroid) {
        await ActivityForegroundService().updateNotification(
          activityName: updated.activityName,
          duration: updated.formattedDuration,
          isPaused: true,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resumeActivity() async {
    if (_runningTrack == null || !_runningTrack!.isPaused) return;

    try {
      // Calculate total paused time and add to accumulated paused duration
      final pauseDuration = _runningTrack!.pauseStartTime != null
          ? DateTime.now().difference(_runningTrack!.pauseStartTime!).inSeconds
          : 0;

      final updated = _runningTrack!.copyWith(
        isPaused: false,
        pausedDuration: _runningTrack!.pausedDuration + pauseDuration,
        clearPauseStartTime: true,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateActivityTrack(updated);
      _runningTrack = updated;

      // Update in list
      final index = _activityTracks.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _activityTracks[index] = updated;
      }

      // Update foreground service (Android only)
      if (Platform.isAndroid) {
        await ActivityForegroundService().updateNotification(
          activityName: updated.activityName,
          duration: updated.formattedDuration,
          isPaused: false,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stopActivity() async {
    if (_runningTrack == null) return;

    try {
      // If paused, add current pause duration to total
      int finalPausedDuration = _runningTrack!.pausedDuration;
      if (_runningTrack!.isPaused && _runningTrack!.pauseStartTime != null) {
        final currentPauseDuration = DateTime.now().difference(_runningTrack!.pauseStartTime!).inSeconds;
        finalPausedDuration += currentPauseDuration;
      }

      final updated = _runningTrack!.copyWith(
        endTime: DateTime.now(),
        isRunning: false,
        isPaused: false,
        pausedDuration: finalPausedDuration,
        clearPauseStartTime: true,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateActivityTrack(updated);
      _runningTrack = null;

      // Update in list
      final index = _activityTracks.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _activityTracks[index] = updated;
      }

      // Stop foreground service (Android only)
      if (Platform.isAndroid) {
        await ActivityForegroundService().stopService();
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTrack(ActivityTrack track) async {
    try {
      final updated = track.copyWith(updatedAt: DateTime.now());
      await _databaseService.updateActivityTrack(updated);

      // Update in list
      final index = _activityTracks.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _activityTracks[index] = updated;
      }

      // Update running track if it's the same
      if (_runningTrack?.id == updated.id) {
        _runningTrack = updated;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTrack(String trackId) async {
    try {
      await _databaseService.deleteActivityTrack(trackId);
      _activityTracks.removeWhere((t) => t.id == trackId);

      if (_runningTrack?.id == trackId) {
        _runningTrack = null;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, Duration>> getStatsByCategory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _databaseService.getActivityStatsByCategory(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Map<String, Duration>> getStatsByActivity({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _databaseService.getActivityStatsByName(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Duration getTotalDuration(List<ActivityTrack> tracks) {
    Duration total = Duration.zero;
    for (final track in tracks) {
      total += track.duration;
    }
    return total;
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    // Show seconds only when duration is less than 1 minute
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Predefined Activity Management
  Future<void> addPredefinedActivity(PredefinedActivity activity) async {
    try {
      await _databaseService.insertPredefinedActivity(activity);
      _predefinedActivities.add(activity);
      _predefinedActivities.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePredefinedActivity(PredefinedActivity activity) async {
    try {
      await _databaseService.updatePredefinedActivity(activity);
      final index = _predefinedActivities.indexWhere((a) => a.id == activity.id);
      if (index != -1) {
        _predefinedActivities[index] = activity;
        _predefinedActivities.sort((a, b) => a.name.compareTo(b.name));
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePredefinedActivity(String id) async {
    try {
      await _databaseService.deletePredefinedActivity(id);
      _predefinedActivities.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
