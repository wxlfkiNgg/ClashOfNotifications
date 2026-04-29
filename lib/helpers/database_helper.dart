import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/timer_model.dart';
import '../models/time_colour_period_model.dart';
import '../models/player_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableNameTimers = 'timers';
  static const String tableNameUpgrades = 'upgrades';
  static const String tableNameSettings = 'settings';
  static const String tableNamePlayers = 'players';

  static List<Map<String, dynamic>>? _upgrades;

  static const List<Map<String, dynamic>> defaultPlayersData = [
    {
      'Name': 'wolfdakiNgg',
      'Tag': '#Q0YY0CR0',
      'ColourValue': 4283215696,
      'Active': 1,
      'DisplayOrder': 0,
      'ExportClockTowerBoost': 1,
      'ExportHelperTimer': 1,
      'ExportBuilderBaseUpgrades': 1,
    },
    {
      'Name': 'Splyce',
      'Tag': '#GRJLG0RR0',
      'ColourValue': 4280690210,
      'Active': 1,
      'DisplayOrder': 1,
      'ExportClockTowerBoost': 1,
      'ExportHelperTimer': 1,
      'ExportBuilderBaseUpgrades': 1,
    },
    {
      'Name': 'P.L.U.C.K.',
      'Tag': '#GQUV2JRY2',
      'ColourValue': 4294924066,
      'Active': 1,
      'DisplayOrder': 2,
      'ExportClockTowerBoost': 1,
      'ExportHelperTimer': 1,
      'ExportBuilderBaseUpgrades': 1,
    },
    {
      'Name': 'The Big Fella',
      'Tag': '#L9L80R00',
      'ColourValue': 4283215696,
      'Active': 1,
      'DisplayOrder': 3,
      'ExportClockTowerBoost': 1,
      'ExportHelperTimer': 1,
      'ExportBuilderBaseUpgrades': 1,
    },
  ];

  final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();
  
  void initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> _loadUpgrades() async {
    if (_upgrades != null) return;
    final String jsonString = await rootBundle.loadString('assets/upgrades.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _upgrades = jsonList.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, 'timers.db');

    // Extract major version from app version (e.g., "1.0.0+1" -> 1)
    final packageInfo = await PackageInfo.fromPlatform();
    final majorVersion = int.parse(packageInfo.version.split('.').first);

    return openDatabase(
      dbFilePath,
      version: majorVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableNameTimers (
            TimerId INTEGER PRIMARY KEY AUTOINCREMENT,
            Player TEXT,
            PlayerTag TEXT,
            VillageType TEXT,
            UpgradeId INTEGER,
            TimerName TEXT,
            UpgradeType TEXT,
            UpgradeLevel INTEGER,
            ReadyDateTime TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableNameSettings (
            SettingId INTEGER PRIMARY KEY AUTOINCREMENT,
            Label TEXT,
            StartHour INTEGER,
            EndHour INTEGER,
            ColourValue INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableNamePlayers (
            PlayerId INTEGER PRIMARY KEY AUTOINCREMENT,
            Name TEXT,
            Tag TEXT,
            ColourValue INTEGER,
            Active INTEGER DEFAULT 1,
            DisplayOrder INTEGER DEFAULT 0,
            ExportClockTowerBoost INTEGER DEFAULT 1,
            ExportHelperTimer INTEGER DEFAULT 1,
            ExportBuilderBaseUpgrades INTEGER DEFAULT 1
          )
        ''');

        final batch = db.batch();
        for (final player in defaultPlayersData) {
          batch.insert(tableNamePlayers, player,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }

        await batch.commit(noResult: true);
      },
    );
  }

  Future<void> insertTimer(TimerModel timer) async {
    final db = await database;
    timer.timerId = await db.insert('timers', timer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
    
    await _scheduleNotification(timer);
  }

  Future<List<TimerModel>> getTimers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableNameTimers);
    return List.generate(maps.length, (i) => TimerModel.fromMap(maps[i]));
  }

  Future<void> deleteTimer(int id) async {
    final db = await database;
    await db.delete(tableNameTimers, where: 'TimerId = ?', whereArgs: [id]);

    await notificationsPlugin.cancel(id: id);
  }

  Future<void> deleteTimersForPlayerTag(
    String playerName,
    String playerTag,
  ) async {
    final db = await database;

    final timers = List<Map<String, dynamic>>.from(
      await db.query(
        tableNameTimers,
        where: 'PlayerTag = ? OR (PlayerTag IS NULL AND Player = ?)',
        whereArgs: [playerTag, playerName],
      ),
    );

    for (final timer in timers) {
      final int? id = timer['TimerId'] as int?;

      if (id != null) {
        await notificationsPlugin.cancel(id: id);

        await db.delete(
          tableNameTimers,
          where: 'TimerId = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Future<String?> getUpgradeName(int upgradeId) async {
    await _loadUpgrades();
    final upgrade = _upgrades!.firstWhere(
      (u) => u['id'] == upgradeId,
      orElse: () => <String, dynamic>{},
    );
    return upgrade['name'] as String?;
  }
  
  Future<String?> getUpgradeTypeFromUpgradeId(int? upgradeId) async {
    if (upgradeId == null) return null;
    await _loadUpgrades();
    final upgrade = _upgrades!.firstWhere(
      (u) => u['id'] == upgradeId,
      orElse: () => <String, dynamic>{},
    );
    return upgrade['type'] as String?;
  }

  Future<List<TimeColourPeriodModel>> getTimeColourPeriods() async {
    final db = await database;
    final maps = await db.query(
      tableNameSettings,
      orderBy: 'StartHour ASC',
    );
    return maps.map((map) => TimeColourPeriodModel.fromMap(map)).toList();
  }

  Future<void> saveTimeColourPeriods(
      List<TimeColourPeriodModel> periods) async {
    final db = await database;
    final batch = db.batch();
    await db.delete(tableNameSettings);
    for (final period in periods) {
      batch.insert(tableNameSettings, period.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteTimeColourPeriod(int id) async {
    final db = await database;
    await db.delete(
      tableNameSettings,
      where: 'SettingId = ?',
      whereArgs: [id],
    );
  }

  Future<List<PlayerModel>> getPlayers() async {
    final db = await database;
    final maps = await db.query(
      tableNamePlayers,
      orderBy: 'DisplayOrder ASC, Name ASC',
    );
    return maps.map((map) => PlayerModel.fromMap(map)).toList();
  }

  Future<void> savePlayers(List<PlayerModel> players) async {
    final db = await database;
    final batch = db.batch();
    await db.delete(tableNamePlayers);
    for (final player in players) {
      batch.insert(tableNamePlayers, player.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deletePlayer(int id) async {
    final db = await database;
    await db.delete(
      tableNamePlayers,
      where: 'PlayerId = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePlayerExportSettings(PlayerModel player) async {
    final db = await database;
    await db.update(
      tableNamePlayers,
      {
        'ExportClockTowerBoost': player.exportClockTowerBoost ? 1 : 0,
        'ExportHelperTimer': player.exportHelperTimer ? 1 : 0,
        'ExportBuilderBaseUpgrades': player.exportBuilderBaseUpgrades ? 1 : 0,
      },
      where: 'PlayerId = ?',
      whereArgs: [player.id],
    );
  }

  Future<void> updateTimersForPlayerName(
      String oldPlayerName, String newPlayerName) async {
    final db = await database;
    await db.update(
      tableNameTimers,
      {'Player': newPlayerName},
      where: 'Player = ?',
      whereArgs: [oldPlayerName],
    );
  }

  Future<void> _scheduleNotification(TimerModel timer) async {
    String upgradeMessage;
    bool quietNotification = false;
    if (timer.timerName == 'Helpers Ready') {
      upgradeMessage = 'Helpers are ready for action';
      quietNotification = true;
    } else if (timer.timerName == 'Clock Tower Boost Ready') {
      upgradeMessage = 'Clock Tower Boost is ready';
      quietNotification = true;
    } else {
      upgradeMessage = '${timer.timerName} has finished upgrading to level ${timer.upgradeLevel}';
    }
    
    // These villages aren't important so no sound is necessary
    if (timer.player.contains('Bruce') || timer.player == 'Joe') {
      quietNotification = true;
    }

    AndroidNotificationDetails androidDetails;

    if (quietNotification) {
      androidDetails = const AndroidNotificationDetails(
        'timer_channel_quiet',
        'Timer Notifications Quiet',
        importance: Importance.max,
        priority: Priority.high,
        playSound: false,
        sound: null,
      );
    }
    else {
      androidDetails = const AndroidNotificationDetails(
        'timer_channel',
        'Timer Notifications',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
      );
    }

    await notificationsPlugin.zonedSchedule(
      id: timer.timerId!,
      title: timer.player,
      body: upgradeMessage,
      scheduledDate: tz.TZDateTime.from(timer.readyDateTime, tz.local),
      notificationDetails: NotificationDetails(
        android: androidDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
