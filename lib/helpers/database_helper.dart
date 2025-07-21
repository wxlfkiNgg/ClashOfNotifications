import 'package:clashofnotifications/models/helper_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/timer_model.dart';
import '../models/boost_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class DatabaseHelper {
  static Database? _database;
  static const String tableNameTimers = 'timers';
  static const String tableNameHelpers = 'helpers';

  final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();
  
  void initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    notificationsPlugin.initialize(initializationSettings);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, 'timers.db');

    return openDatabase(
      dbFilePath,
      version: 1,
      onCreate: (db, version) async {
        // Create the timers table
        await db.execute('''
          CREATE TABLE $tableNameTimers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player TEXT,
            village TEXT,
            upgrade TEXT,
            expiry TEXT,
            isFinished BOOL
          )
        ''');
        // Create the helpers table
        await db.execute('''
          CREATE TABLE $tableNameHelpers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player TEXT,
            type TEXT,
            amount INTEGER
          )
        ''');
      },
    );

  }

  Future<void> insertTimer(TimerModel timer) async {
    final db = await database;
    timer.id = await db.insert('timers', timer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Schedule notification after inserting
    await _scheduleNotification(timer);
  }

  Future<List<TimerModel>> getTimers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableNameTimers);
    return List.generate(maps.length, (i) => TimerModel.fromMap(maps[i]));
  }

  Future<void> deleteTimer(int id) async {
    final db = await database;
    await db.delete(tableNameTimers, where: 'id = ?', whereArgs: [id]);

    await notificationsPlugin.cancel(id);
  }

  Future<void> updateTimer(TimerModel timer) async {
    final db = await database;
    await db.update(
      'timers',
      timer.toMap(),
      where: 'id = ?',
      whereArgs: [timer.id],
    );

    if (!timer.isFinished) {
      // Cancel existing notification and reschedule
      await notificationsPlugin.cancel(timer.id!);
      await _scheduleNotification(timer);
    }
  }
  
  Future<void> insertHelper(HelperModel helper) async {
    final db = await database;
    helper.id = await db.insert('helpers', helper.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
    
  }

  Future<List<HelperModel>> getHelpers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableNameHelpers);
    return List.generate(maps.length, (i) => HelperModel.fromMap(maps[i]));
  }

  Future<void> deleteHelper(int? id) async {
    if (id != null) {
      final db = await database;
      await db.delete(tableNameHelpers, where: 'id = ?', whereArgs: [id]);

      await notificationsPlugin.cancel(id);
    }
  }

  Future<void> updateHelper(HelperModel helper) async {
    final db = await database;
    await db.update(
      'helpers',
      helper.toMap(),
      where: 'id = ?',
      whereArgs: [helper.id],
    );
  }

  Future<void> applyBoostAndRescheduleTimers(BoostModel boost) async {
    // Fetch all timers
    final timers = await getTimers();

    // Iterate over each timer and apply the boost logic if it's affected by this boost
    for (final timer in timers) {
      if (!boost.affectedTimerIds.contains(timer.id)) continue;

      final originalTimeRemaining = timer.expiry.difference(DateTime.now());
      Duration adjustedTimeRemaining = originalTimeRemaining;

      if (boost.amount > 1 && boost.duration.inSeconds > 0) {
        final T = originalTimeRemaining.inSeconds.toDouble();
        final M = boost.amount;
        final D = boost.duration.inSeconds.toDouble();
        final boostCoverage = M * D;

        double adjustedSeconds;
        if (T <= boostCoverage) {
          adjustedSeconds = T / M;
        } else {
          adjustedSeconds = D + (T - boostCoverage);
        }

        adjustedTimeRemaining = Duration(seconds: adjustedSeconds.floor());
      }

      // Calculate the new expiry time based on adjusted time remaining
      final adjustedExpiry = DateTime.now().add(adjustedTimeRemaining);

      // Create a new timer with the updated expiry time
      final updatedTimer = timer.copyWith(expiry: adjustedExpiry);

      // Update the timer in the database and reschedule its notification
      await updateTimer(updatedTimer); // Handles DB update + notification reschedule
    }
  }

  Future<void> _scheduleNotification(TimerModel timer) async {
    String upgradeMessage;
    if (timer.upgrade == 'Helpers Ready') {
      upgradeMessage = 'Helpers are ready!';
    } else {
      upgradeMessage = '${timer.upgrade} has finished upgrading.';
    }

    await notificationsPlugin.zonedSchedule(
      timer.id!,
      timer.player,
      upgradeMessage,
      tz.TZDateTime.from(timer.expiry, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'timer_channel',
          'Timer Notifications',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  // Fetch helpers for a specific village
  Future<List<HelperModel>> getHelpersForVillage(String player) async {
    // Example: If helpers are not tied to a village, just return all
    // If they are, filter by village
    final db = await database;
    final result = await db.query(
      'helpers',
      where: 'player = ?',
      whereArgs: [player],
    );
    return result.map((json) => HelperModel.fromMap(json)).toList();
  }

  Future<TimerModel?> getHelpersReadyTimer(String player) async {
    final db = await database;
    final result = await db.query(
      'timers',
      where: 'player = ? AND upgrade = ?',
      whereArgs: [player, 'Helpers Ready'],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return TimerModel.fromMap(result.first);
    }
    return null;
  }
}
