import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'local_database_service.dart';

/// Foreground service for activity tracking that runs even when app is closed
class ActivityForegroundService {
  static final ActivityForegroundService _instance = ActivityForegroundService._internal();
  factory ActivityForegroundService() => _instance;
  ActivityForegroundService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!Platform.isAndroid || _isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'activity_tracker_foreground',
        channelName: 'Aktivitäts-Tracker',
        channelDescription: 'Läuft im Hintergrund um Aktivitäten zu tracken',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // Update every 5 seconds
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
  }

  Future<void> startService({
    required String activityId,
    required String activityName,
  }) async {
    if (!Platform.isAndroid) return;

    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: activityName,
        notificationText: 'Tracking läuft...',
        notificationIcon: null,
        notificationButtons: [
          const NotificationButton(
            id: 'pause',
            text: 'Pausieren',
          ),
          const NotificationButton(
            id: 'stop',
            text: 'Beenden',
          ),
        ],
        callback: startCallback,
      );
    }
  }

  Future<void> stopService() async {
    if (!Platform.isAndroid) return;

    await FlutterForegroundTask.stopService();
  }

  Future<void> updateNotification({
    required String activityName,
    required String duration,
    required bool isPaused,
  }) async {
    if (!Platform.isAndroid) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: activityName,
      notificationText: isPaused ? 'Pausiert • $duration' : duration,
      notificationButtons: [
        NotificationButton(
          id: isPaused ? 'resume' : 'pause',
          text: isPaused ? 'Fortsetzen' : 'Pausieren',
        ),
        const NotificationButton(
          id: 'stop',
          text: 'Beenden',
        ),
      ],
    );
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ActivityTrackingTaskHandler());
}

class ActivityTrackingTaskHandler extends TaskHandler {
  final LocalDatabaseService _databaseService = LocalDatabaseService();
  Timer? _updateTimer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Start periodic updates
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _updateActivityDuration();
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // This is called every 5 seconds (configured in foregroundTaskOptions)
    await _updateActivityDuration();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _updateTimer?.cancel();
  }

  @override
  void onNotificationButtonPressed(String id) {
    // Send event to main isolate
    FlutterForegroundTask.sendDataToMain({
      'action': id, // 'pause', 'resume', or 'stop'
    });
  }

  Future<void> _updateActivityDuration() async {
    try {
      final runningTrack = await _databaseService.getRunningActivityTrack();
      if (runningTrack == null) {
        // No running activity, stop service
        FlutterForegroundTask.stopService();
        return;
      }

      final duration = runningTrack.formattedDuration;

      await FlutterForegroundTask.updateService(
        notificationTitle: runningTrack.activityName,
        notificationText: runningTrack.isPaused ? 'Pausiert • $duration' : duration,
        notificationButtons: [
          NotificationButton(
            id: runningTrack.isPaused ? 'resume' : 'pause',
            text: runningTrack.isPaused ? 'Fortsetzen' : 'Pausieren',
          ),
          const NotificationButton(
            id: 'stop',
            text: 'Beenden',
          ),
        ],
      );
    } catch (e) {
      // Silently fail
    }
  }
}
