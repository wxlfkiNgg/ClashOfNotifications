import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/timer_model.dart';
import '../models/boost_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'timers';

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
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player TEXT,
            village TEXT,
            upgrade TEXT,
            expiry TEXT,
            isFinished BOOL
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
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) => TimerModel.fromMap(maps[i]));
  }

  Future<void> deleteTimer(int id) async {
    final db = await database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);

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
    await notificationsPlugin.zonedSchedule(
      timer.id!,
      "${timer.player} - ${timer.village}",
      "${timer.upgrade} has finished upgrading.",
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
}
