import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../models/category.dart';
import '../models/schedule_item.dart';
import '../services/local_database_service.dart';
import '../services/notification_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final LocalDatabaseService _databaseService = LocalDatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<ScheduleItem> _scheduleItems = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Cache für Kalenderansicht
  final Map<String, List<ScheduleItem>> _dateCache = {};

  List<ScheduleItem> get scheduleItems => _scheduleItems;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor: Load data when provider is created
  ScheduleProvider() {
    loadData();
  }

  Future<void> loadData() async {
    try {
      _isLoading = true;
      notifyListeners();

      await Future.wait([
        loadScheduleItems(),
        loadCategories(),
      ]);

      _isLoading = false;
      notifyListeners();

      // Update ongoing notification after loading data
      if (Platform.isAndroid) {
        await _updateOngoingNotificationWithCategory();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadScheduleItems({DateTime? startDate, DateTime? endDate}) async {
    try {
      _scheduleItems = await _databaseService.getScheduleItems();
      // Filter by date range if provided
      if (startDate != null && endDate != null) {
        _scheduleItems = _scheduleItems.where((item) {
          return item.startTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
              item.startTime.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _databaseService.getCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    try {
      await _databaseService.insertScheduleItem(item);
      _scheduleItems.add(item);
      _scheduleItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      _clearCache();

      // Update ongoing notification for Android
      if (Platform.isAndroid) {
        await _updateOngoingNotificationWithCategory();
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateScheduleItem(ScheduleItem item) async {
    try {
      await _databaseService.updateScheduleItem(item);
      final index = _scheduleItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _scheduleItems[index] = item;
        _scheduleItems.sort((a, b) => a.startTime.compareTo(b.startTime));
        _clearCache();

        // Update ongoing notification for Android
        if (Platform.isAndroid) {
          await _updateOngoingNotificationWithCategory();
        }

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteScheduleItem(String itemId) async {
    try {
      await _databaseService.deleteScheduleItem(itemId);
      _scheduleItems.removeWhere((i) => i.id == itemId);
      _clearCache();

      // Update ongoing notification for Android
      if (Platform.isAndroid) {
        await _updateOngoingNotificationWithCategory();
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      await _databaseService.insertCategory(category);
      _categories.add(category);
      _categories.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _databaseService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        _categories.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _databaseService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _clearCache() {
    _dateCache.clear();
  }

  List<ScheduleItem> getItemsForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';

    if (_dateCache.containsKey(dateKey)) {
      return _dateCache[dateKey]!;
    }

    final items = _scheduleItems.where((item) => item.isOnDate(date)).toList();
    _dateCache[dateKey] = items;
    return items;
  }

  List<ScheduleItem> getItemsForDateRange(DateTime start, DateTime end) {
    return _scheduleItems.where((item) {
      return item.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
          item.startTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Category? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Helper method to update ongoing notification with category name
  Future<void> _updateOngoingNotificationWithCategory() async {
    // Find next upcoming event
    final now = DateTime.now();
    final upcomingItems = _scheduleItems
        .where((item) => item.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final nextItem = upcomingItems.isNotEmpty ? upcomingItems.first : null;
    String? categoryName;

    if (nextItem != null && nextItem.categoryId != null) {
      final category = getCategoryById(nextItem.categoryId);
      categoryName = category?.name;
    }

    await _notificationService.updateOngoingNotification(
      _scheduleItems,
      categoryName: categoryName,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
