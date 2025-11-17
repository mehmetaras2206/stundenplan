import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule_item.dart';
import '../models/category.dart';
import '../models/activity_track.dart';
import '../models/predefined_activity.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  static Database? _database;

  factory LocalDatabaseService() {
    return _instance;
  }

  LocalDatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stundenplan.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Recreate schedule_items table to ensure all columns exist
      await db.execute('DROP TABLE IF EXISTS schedule_items');
      await db.execute('''
        CREATE TABLE schedule_items (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL DEFAULT '',
          title TEXT NOT NULL,
          description TEXT,
          location TEXT,
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          color INTEGER,
          category_id TEXT,
          is_recurring INTEGER NOT NULL DEFAULT 0,
          recurrence_rule TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add activity_tracks table
      await db.execute('''
        CREATE TABLE activity_tracks (
          id TEXT PRIMARY KEY,
          activity_name TEXT NOT NULL,
          schedule_item_id TEXT,
          category_id TEXT,
          start_time TEXT NOT NULL,
          end_time TEXT,
          is_running INTEGER NOT NULL DEFAULT 0,
          color INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (schedule_item_id) REFERENCES schedule_items (id) ON DELETE SET NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      // Add pause tracking columns to activity_tracks
      await db.execute('''
        ALTER TABLE activity_tracks ADD COLUMN is_paused INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE activity_tracks ADD COLUMN paused_duration INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE activity_tracks ADD COLUMN pause_start_time TEXT
      ''');
    }

    if (oldVersion < 5) {
      // Create predefined_activities table
      await db.execute('''
        CREATE TABLE predefined_activities (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color INTEGER,
          icon_codepoint INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Add predefined_activity_id to activity_tracks
      await db.execute('''
        ALTER TABLE activity_tracks ADD COLUMN predefined_activity_id TEXT
      ''');

      // Add week_start_date to activity_tracks for weekly filtering
      await db.execute('''
        ALTER TABLE activity_tracks ADD COLUMN week_start_date TEXT
      ''');
    }

    if (oldVersion < 6) {
      // Add event_type to schedule_items
      await db.execute('''
        ALTER TABLE schedule_items ADD COLUMN event_type TEXT
      ''');
    }

    if (oldVersion < 7) {
      // Add weekly_goal_hours to categories
      await db.execute('''
        ALTER TABLE categories ADD COLUMN weekly_goal_hours REAL
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        weekly_goal_hours REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create schedule_items table
    await db.execute('''
      CREATE TABLE schedule_items (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        title TEXT NOT NULL,
        event_type TEXT,
        description TEXT,
        location TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        color INTEGER,
        category_id TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurrence_rule TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // Create activity_tracks table
    await db.execute('''
      CREATE TABLE activity_tracks (
        id TEXT PRIMARY KEY,
        activity_name TEXT NOT NULL,
        schedule_item_id TEXT,
        category_id TEXT,
        predefined_activity_id TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        is_running INTEGER NOT NULL DEFAULT 0,
        is_paused INTEGER NOT NULL DEFAULT 0,
        paused_duration INTEGER NOT NULL DEFAULT 0,
        pause_start_time TEXT,
        week_start_date TEXT,
        color INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (schedule_item_id) REFERENCES schedule_items (id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (predefined_activity_id) REFERENCES predefined_activities (id) ON DELETE SET NULL
      )
    ''');

    // Create predefined_activities table
    await db.execute('''
      CREATE TABLE predefined_activities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER,
        icon_codepoint INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // Category operations
  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Category(
        id: maps[i]['id'],
        name: maps[i]['name'],
        color: Color(maps[i]['color']),
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']),
      );
    });
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'color': category.color.toARGB32(),
        'created_at': category.createdAt.toIso8601String(),
        'updated_at': category.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'name': category.name,
        'color': category.color.toARGB32(),
        'updated_at': category.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Schedule item operations
  Future<List<ScheduleItem>> getScheduleItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedule_items',
      orderBy: 'start_time ASC',
    );

    return List.generate(maps.length, (i) {
      return ScheduleItem(
        id: maps[i]['id'],
        userId: maps[i]['user_id'] ?? '',
        title: maps[i]['title'],
        description: maps[i]['description'],
        location: maps[i]['location'],
        startTime: DateTime.parse(maps[i]['start_time']),
        endTime: DateTime.parse(maps[i]['end_time']),
        color: maps[i]['color'] != null ? Color(maps[i]['color']) : null,
        categoryId: maps[i]['category_id'],
        isRecurring: maps[i]['is_recurring'] == 1,
        recurrenceRule: maps[i]['recurrence_rule'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']),
      );
    });
  }

  Future<void> insertScheduleItem(ScheduleItem item) async {
    final db = await database;
    await db.insert(
      'schedule_items',
      {
        'id': item.id,
        'user_id': item.userId,
        'title': item.title,
        'description': item.description,
        'location': item.location,
        'start_time': item.startTime.toIso8601String(),
        'end_time': item.endTime.toIso8601String(),
        'color': item.color?.toARGB32(),
        'category_id': item.categoryId,
        'is_recurring': item.isRecurring ? 1 : 0,
        'recurrence_rule': item.recurrenceRule,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateScheduleItem(ScheduleItem item) async {
    final db = await database;
    await db.update(
      'schedule_items',
      {
        'user_id': item.userId,
        'title': item.title,
        'description': item.description,
        'location': item.location,
        'start_time': item.startTime.toIso8601String(),
        'end_time': item.endTime.toIso8601String(),
        'color': item.color?.toARGB32(),
        'category_id': item.categoryId,
        'is_recurring': item.isRecurring ? 1 : 0,
        'recurrence_rule': item.recurrenceRule,
        'updated_at': item.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteScheduleItem(String id) async {
    final db = await database;
    await db.delete(
      'schedule_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Activity Track operations
  Future<List<ActivityTrack>> getActivityTracks({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      whereClause = 'start_time >= ? AND start_time <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'activity_tracks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'start_time DESC',
    );

    return List.generate(maps.length, (i) {
      return ActivityTrack.fromJson(maps[i]);
    });
  }

  Future<ActivityTrack?> getRunningActivityTrack() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activity_tracks',
      where: 'is_running = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ActivityTrack.fromJson(maps.first);
  }

  Future<void> insertActivityTrack(ActivityTrack track) async {
    final db = await database;
    await db.insert(
      'activity_tracks',
      track.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateActivityTrack(ActivityTrack track) async {
    final db = await database;
    await db.update(
      'activity_tracks',
      track.toJson(),
      where: 'id = ?',
      whereArgs: [track.id],
    );
  }

  Future<void> deleteActivityTrack(String id) async {
    final db = await database;
    await db.delete(
      'activity_tracks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, Duration>> getActivityStatsByCategory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(c.name, 'Ohne Kategorie') as category_name,
        SUM(
          CASE
            WHEN at.end_time IS NULL THEN 0
            ELSE (julianday(at.end_time) - julianday(at.start_time)) * 86400
          END
        ) as total_seconds
      FROM activity_tracks at
      LEFT JOIN categories c ON at.category_id = c.id
      WHERE at.start_time >= ? AND at.start_time <= ?
      GROUP BY category_name
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final Map<String, Duration> stats = {};
    for (final row in result) {
      final categoryName = row['category_name'] as String;
      final totalSeconds = (row['total_seconds'] as num?)?.toInt() ?? 0;
      stats[categoryName] = Duration(seconds: totalSeconds);
    }
    return stats;
  }

  Future<Map<String, Duration>> getActivityStatsByName({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        activity_name,
        SUM(
          CASE
            WHEN end_time IS NULL THEN 0
            ELSE (julianday(end_time) - julianday(start_time)) * 86400
          END
        ) as total_seconds
      FROM activity_tracks
      WHERE start_time >= ? AND start_time <= ?
      GROUP BY activity_name
      ORDER BY total_seconds DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final Map<String, Duration> stats = {};
    for (final row in result) {
      final activityName = row['activity_name'] as String;
      final totalSeconds = (row['total_seconds'] as num?)?.toInt() ?? 0;
      stats[activityName] = Duration(seconds: totalSeconds);
    }
    return stats;
  }

  // Predefined Activity operations
  Future<List<PredefinedActivity>> getPredefinedActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'predefined_activities',
      orderBy: 'name ASC',
    );
    return maps.map((map) => PredefinedActivity.fromJson(map)).toList();
  }

  Future<PredefinedActivity?> getPredefinedActivityById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'predefined_activities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PredefinedActivity.fromJson(maps.first);
  }

  Future<void> insertPredefinedActivity(PredefinedActivity activity) async {
    final db = await database;
    await db.insert(
      'predefined_activities',
      activity.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePredefinedActivity(PredefinedActivity activity) async {
    final db = await database;
    await db.update(
      'predefined_activities',
      activity.toJson(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<void> deletePredefinedActivity(String id) async {
    final db = await database;
    await db.delete(
      'predefined_activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get activity tracks for current week
  Future<List<ActivityTrack>> getActivityTracksForWeek(DateTime weekStart) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activity_tracks',
      where: 'week_start_date = ?',
      whereArgs: [weekStart.toIso8601String()],
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => ActivityTrack.fromJson(map)).toList();
  }
}
