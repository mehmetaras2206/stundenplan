import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/schedule_item.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Callback for activity action buttons
  Function(String action)? onActivityAction;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification actions
    if (response.actionId != null) {
      // Activity notification actions
      if (response.actionId == 'pause' ||
          response.actionId == 'resume' ||
          response.actionId == 'stop') {
        onActivityAction?.call(response.actionId!);
      }
    }
    // Handle notification tap - navigate to schedule item detail
    // This can be enhanced with a navigation callback
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  // Removed: scheduleNotification, scheduleItemNotification, cancelNotification
  // We only use the ongoing notification now

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Removed: scheduleMultipleNotifications, rescheduleAllNotifications
  // We only update the ongoing notification now

  // Show permanent ongoing notification with next event
  Future<void> showOngoingNotification(ScheduleItem? nextItem, {String? categoryName}) async {
    if (!_isInitialized) {
      await initialize();
    }

    const int ongoingNotificationId = 999999;

    if (nextItem == null) {
      // Remove ongoing notification if no events
      await _notifications.cancel(ongoingNotificationId);
      return;
    }

    // Calculate time until event
    final now = DateTime.now();
    final difference = nextItem.startTime.difference(now);
    String timeUntil = '';

    if (difference.inDays > 0) {
      timeUntil = 'in ${difference.inDays} ${difference.inDays == 1 ? "Tag" : "Tagen"}';
    } else if (difference.inHours > 0) {
      timeUntil = 'in ${difference.inHours} ${difference.inHours == 1 ? "Stunde" : "Stunden"}';
    } else if (difference.inMinutes > 0) {
      timeUntil = 'in ${difference.inMinutes} ${difference.inMinutes == 1 ? "Minute" : "Minuten"}';
    } else if (difference.inSeconds > 0) {
      timeUntil = 'gleich';
    } else {
      timeUntil = 'jetzt';
    }

    String body = '${_formatTime(nextItem.startTime)} • $timeUntil';
    if (nextItem.location != null && nextItem.location!.isNotEmpty) {
      body += ' • ${nextItem.location}';
    }

    final androidDetails = AndroidNotificationDetails(
      'ongoing_event',
      'Nächste Veranstaltung',
      channelDescription: 'Zeigt die nächste anstehende Veranstaltung',
      importance: Importance.min,  // MIN = absolut still, nur im Drawer
      priority: Priority.min,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      enableLights: false,
      onlyAlertOnce: true,
      visibility: NotificationVisibility.public,
      styleInformation: const BigTextStyleInformation(''),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      ongoingNotificationId,
      nextItem.title,
      body,
      notificationDetails,
      payload: nextItem.id,
    );
  }

  Future<void> updateOngoingNotification(List<ScheduleItem> allItems, {String? categoryName}) async {
    // Find next upcoming event
    final now = DateTime.now();
    final upcomingItems = allItems
        .where((item) => item.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final nextItem = upcomingItems.isNotEmpty ? upcomingItems.first : null;
    await showOngoingNotification(nextItem, categoryName: categoryName);
  }

  // Activity Tracker Notification
  static const int activityNotificationId = 888888;

  Future<void> showActivityNotification({
    required String activityName,
    required String duration,
    required bool isPaused,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Action buttons
    final List<AndroidNotificationAction> actions = [];

    if (isPaused) {
      actions.add(
        const AndroidNotificationAction(
          'resume',
          'Fortsetzen',
          icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          showsUserInterface: false,
        ),
      );
    } else {
      actions.add(
        const AndroidNotificationAction(
          'pause',
          'Pausieren',
          icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          showsUserInterface: false,
        ),
      );
    }

    actions.add(
      const AndroidNotificationAction(
        'stop',
        'Beenden',
        icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        showsUserInterface: false,
      ),
    );

    final androidDetails = AndroidNotificationDetails(
      'activity_tracker',
      'Aktivitäts-Tracker',
      channelDescription: 'Zeigt laufende Aktivitäten',
      importance: Importance.low,  // LOW = kein Pop-up, nur im Notification Drawer
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,  // Keine Zeitanzeige
      playSound: false,
      enableVibration: false,
      enableLights: false,
      onlyAlertOnce: true,  // Nur beim ersten Mal "alertieren"
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        duration,
        contentTitle: activityName,
        summaryText: isPaused ? 'Pausiert' : 'Läuft',
      ),
      actions: actions,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      activityNotificationId,
      activityName,
      isPaused ? 'Pausiert • $duration' : duration,
      notificationDetails,
    );
  }

  Future<void> cancelActivityNotification() async {
    await _notifications.cancel(activityNotificationId);
  }
}
