import 'dart:io' show Platform;
import 'package:workmanager/workmanager.dart';
import 'local_database_service.dart';
import 'notification_service.dart';

const String updateNotificationTask = 'updateNotificationTask';

/// Background callback that runs independently of the main app
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize services
      final databaseService = LocalDatabaseService();
      final notificationService = NotificationService();

      await notificationService.initialize();

      // Get all schedule items and categories
      final scheduleItems = await databaseService.getScheduleItems();
      final categories = await databaseService.getCategories();

      // Find next upcoming event and its category
      final now = DateTime.now();
      final upcomingItems = scheduleItems
          .where((item) => item.startTime.isAfter(now))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      String? categoryName;
      if (upcomingItems.isNotEmpty) {
        final nextItem = upcomingItems.first;
        if (nextItem.categoryId != null) {
          try {
            final category = categories.firstWhere(
              (c) => c.id == nextItem.categoryId,
            );
            categoryName = category.name;
          } catch (e) {
            // Category not found, categoryName remains null
          }
        }
      }

      // Update the ongoing notification with next upcoming event
      await notificationService.updateOngoingNotification(
        scheduleItems,
        categoryName: categoryName,
      );

      return Future.value(true);
    } catch (e) {
      // Log error silently
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  /// Initialize the background service
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  /// Schedule periodic background updates
  Future<void> schedulePeriodicUpdates() async {
    if (!Platform.isAndroid) return;

    // Cancel any existing tasks
    await Workmanager().cancelByUniqueName(updateNotificationTask);

    // Schedule periodic task to run every 15 minutes
    await Workmanager().registerPeriodicTask(
      updateNotificationTask,
      updateNotificationTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  /// Schedule a one-time update at a specific time
  Future<void> scheduleOneTimeUpdate({Duration delay = Duration.zero}) async {
    if (!Platform.isAndroid) return;

    await Workmanager().registerOneOffTask(
      'oneTimeUpdate_${DateTime.now().millisecondsSinceEpoch}',
      updateNotificationTask,
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  /// Cancel all background tasks
  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;

    await Workmanager().cancelAll();
  }

  /// Schedule updates to run at specific times when events start/end
  Future<void> scheduleUpdatesForEvents(List<DateTime> eventTimes) async {
    if (!Platform.isAndroid) return;

    final now = DateTime.now();

    for (final eventTime in eventTimes) {
      if (eventTime.isAfter(now)) {
        final delay = eventTime.difference(now);

        // Schedule update right after event starts
        await scheduleOneTimeUpdate(delay: delay);

        // Also schedule 1 minute after to ensure update happens
        await scheduleOneTimeUpdate(
          delay: delay.inMinutes > 0
            ? delay + const Duration(minutes: 1)
            : const Duration(minutes: 1),
        );
      }
    }
  }
}
