// Background Service Stub
//
// Previously used workmanager for periodic updates.
// Now the app uses flutter_foreground_task for time tracking,
// and notifications are handled by notification_service.dart.
// This stub is kept for compatibility.

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  /// Initialize the background service (no-op)
  Future<void> initialize() async {
    // No longer needed - using foreground_task for tracking
  }

  /// Schedule periodic background updates (no-op)
  Future<void> schedulePeriodicUpdates() async {
    // No longer needed - notifications handled elsewhere
  }

  /// Cancel all background tasks (no-op)
  Future<void> cancelAll() async {
    // No-op
  }
}
