import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/category.dart';
import '../models/schedule_item.dart';
import 'local_database_service.dart';

class ExportImportService {
  final LocalDatabaseService _databaseService = LocalDatabaseService();

  /// Export all data to JSON file
  Future<String?> exportData() async {
    try {
      // Get all data from database
      final categories = await _databaseService.getCategories();
      final scheduleItems = await _databaseService.getScheduleItems();

      // Create export data structure
      final exportData = {
        'version': 1,
        'export_date': DateTime.now().toIso8601String(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'schedule_items': scheduleItems.map((s) => s.toJson()).toList(),
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'stundenplan_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      // Export failed, rethrow to show error
      rethrow;
    }
  }

  /// Share exported data file
  Future<bool> shareExportedData() async {
    try {
      final filePath = await exportData();
      if (filePath == null) return false;

      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final result = await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/json')],
        subject: 'Stundenplan Backup',
        text: 'Mein Stundenplan Export vom ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
      );

      return result.status == ShareResultStatus.success ||
             result.status == ShareResultStatus.unavailable; // Sometimes unavailable is returned even when it works
    } catch (e) {
      // Share failed, rethrow to show error
      rethrow;
    }
  }

  /// Import data from JSON file
  Future<ImportResult> importData() async {
    try {
      // Let user pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return ImportResult(
          success: false,
          message: 'Keine Datei ausgewählt',
        );
      }

      // Read file content
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> importData = json.decode(jsonString);

      // Validate format
      if (!importData.containsKey('version') ||
          !importData.containsKey('categories') ||
          !importData.containsKey('schedule_items')) {
        return ImportResult(
          success: false,
          message: 'Ungültiges Dateiformat',
        );
      }

      // Parse categories
      final List<Category> categories = [];
      for (final categoryJson in importData['categories']) {
        try {
          categories.add(Category.fromJson(categoryJson));
        } catch (e) {
          // Skip invalid category
        }
      }

      // Parse schedule items
      final List<ScheduleItem> scheduleItems = [];
      for (final itemJson in importData['schedule_items']) {
        try {
          scheduleItems.add(ScheduleItem.fromJson(itemJson));
        } catch (e) {
          // Skip invalid schedule item
        }
      }

      // Import categories first (due to foreign key constraint)
      for (final category in categories) {
        try {
          await _databaseService.insertCategory(category);
        } catch (e) {
          // Category might already exist, skip
        }
      }

      // Import schedule items
      int importedItems = 0;
      for (final item in scheduleItems) {
        try {
          await _databaseService.insertScheduleItem(item);
          importedItems++;
        } catch (e) {
          // Skip item if import fails
        }
      }

      return ImportResult(
        success: true,
        message: '$importedItems Veranstaltungen und ${categories.length} Kategorien importiert',
        categoriesImported: categories.length,
        itemsImported: importedItems,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Fehler beim Importieren: $e',
      );
    }
  }

  /// Clear all data (useful before import to avoid duplicates)
  Future<void> clearAllData() async {
    final scheduleItems = await _databaseService.getScheduleItems();
    for (final item in scheduleItems) {
      await _databaseService.deleteScheduleItem(item.id);
    }

    final categories = await _databaseService.getCategories();
    for (final category in categories) {
      await _databaseService.deleteCategory(category.id);
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int categoriesImported;
  final int itemsImported;

  ImportResult({
    required this.success,
    required this.message,
    this.categoriesImported = 0,
    this.itemsImported = 0,
  });
}
