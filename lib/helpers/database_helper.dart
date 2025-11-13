import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/timer_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class DatabaseHelper {
  static Database? _database;
  static const String tableNameTimers = 'timers';
  static const String tableNameUpgrades = 'upgrades';

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
        await db.execute('''
          CREATE TABLE $tableNameTimers (
            TimerId INTEGER PRIMARY KEY AUTOINCREMENT,
            Player TEXT,
            VillageType TEXT,
            UpgradeId INTEGER,
            TimerName TEXT,
            UpgradeType TEXT,
            ReadyDateTime TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE $tableNameUpgrades (
            RecordId INTEGER PRIMARY KEY AUTOINCREMENT,
            UpgradeId INTEGER,
            UpgradeName TEXT,
            UpgradeType
          )
        ''');

        final batch = db.batch();

        final upgrades = [
          {'id': 1000000, 'name': 'Army Camp', 'type': 'Building'},
          {'id': 1000001, 'name': 'Town Hall', 'type': 'Building'},
          {'id': 1000002, 'name': 'Elixir Collector', 'type': 'Building'},
          {'id': 1000003, 'name': 'Elixir Storage', 'type': 'Building'},
          {'id': 1000004, 'name': 'Gold Mine', 'type': 'Building'},
          {'id': 1000005, 'name': 'Gold Storage', 'type': 'Building'},
          {'id': 1000006, 'name': 'Barracks', 'type': 'Building'},
          {'id': 1000007, 'name': 'Laboratory', 'type': 'Building'},
          {'id': 1000008, 'name': 'Cannon', 'type': 'Building'},
          {'id': 1000009, 'name': 'Archer Tower', 'type': 'Building'},
          {'id': 1000010, 'name': 'Wall', 'type': 'Building'},
          {'id': 1000011, 'name': 'Wizard Tower', 'type': 'Building'},
          {'id': 1000012, 'name': 'Air Defense', 'type': 'Building'},
          {'id': 1000013, 'name': 'Mortar', 'type': 'Building'},
          {'id': 1000014, 'name': 'Clan Castle', 'type': 'Building'},
          {'id': 1000015, 'name': 'Builder Hut', 'type': 'Building'},
          {'id': 1000019, 'name': 'Hidden Tesla', 'type': 'Building'},
          {'id': 1000020, 'name': 'Spell Factory', 'type': 'Building'},
          {'id': 1000021, 'name': 'X-Bow', 'type': 'Building'},
          {'id': 1000023, 'name': 'Dark Elixir Drill', 'type': 'Building'},
          {'id': 1000024, 'name': 'Dark Elixir Storage', 'type': 'Building'},
          {'id': 1000026, 'name': 'Dark Barracks', 'type': 'Building'},
          {'id': 1000027, 'name': 'Inferno Tower', 'type': 'Building'},
          {'id': 1000028, 'name': 'Air Sweeper', 'type': 'Building'},
          {'id': 1000029, 'name': 'Dark Spell Factory', 'type': 'Building'},
          {'id': 1000031, 'name': 'Eagle Artillery', 'type': 'Building'},
          {'id': 1000032, 'name': 'Bomb Tower', 'type': 'Building'},
          {'id': 1000033, 'name': 'Wall', 'type': 'Building'},
          {'id': 1000034, 'name': 'Builder Hall', 'type': 'Building'},
          {'id': 1000035, 'name': 'Elixir Collector', 'type': 'Building'},
          {'id': 1000036, 'name': 'Elixir Storage', 'type': 'Building'},
          {'id': 1000037, 'name': 'Gold Mine', 'type': 'Building'},
          {'id': 1000038, 'name': 'Gold Storage', 'type': 'Building'},
          {'id': 1000039, 'name': 'Clock Tower', 'type': 'Building'},
          {'id': 1000040, 'name': 'Builder Barracks', 'type': 'Building'},
          {'id': 1000041, 'name': 'Double Cannon', 'type': 'Building'},
          {'id': 1000042, 'name': 'Army Camp', 'type': 'Building'},
          {'id': 1000043, 'name': 'Hidden Tesla', 'type': 'Building'},
          {'id': 1000044, 'name': 'Cannon', 'type': 'Building'},
          {'id': 1000045, 'name': 'Multi Mortar', 'type': 'Building'},
          {'id': 1000046, 'name': 'Star Laboratory', 'type': 'Building'},
          {'id': 1000048, 'name': 'Archer Tower', 'type': 'Building'},
          {'id': 1000049, 'name': 'Reinforcement Camp', 'type': 'Building'},
          {'id': 1000050, 'name': 'Firecrackers', 'type': 'Building'},
          {'id': 1000051, 'name': 'Guard Post', 'type': 'Building'},
          {'id': 1000052, 'name': 'Mega Tesla', 'type': 'Building'},
          {'id': 1000054, 'name': 'Air Bombs', 'type': 'Building'},
          {'id': 1000055, 'name': 'Crusher', 'type': 'Building'},
          {'id': 1000056, 'name': 'Roaster', 'type': 'Building'},
          {'id': 1000057, 'name': 'Giant Cannon', 'type': 'Building'},
          {'id': 1000058, 'name': 'Gem Mine', 'type': 'Building'},
          {'id': 1000059, 'name': 'Workshop', 'type': 'Building'},
          {'id': 1000063, 'name': 'Lava Launcher', 'type': 'Building'},
          {'id': 1000065, 'name': 'B.O.B Control/X-Bow', 'type': 'Building'},
          {'id': 1000067, 'name': 'Scattershot', 'type': 'Building'},
          {'id': 1000068, 'name': 'Pet House', 'type': 'Building'},
          {'id': 1000070, 'name': 'Blacksmith', 'type': 'Building'},
          {'id': 1000071, 'name': 'Hero Hall', 'type': 'Building'},
          {'id': 1000072, 'name': 'Spell Tower', 'type': 'Building'},
          {'id': 1000077, 'name': 'Monolith', 'type': 'Building'},
          {'id': 1000078, 'name': 'O.T.T.O''s Outpost', 'type': 'Building'},
          {'id': 1000079, 'name': 'Multi-Gear Tower', 'type': 'Building'},
          {'id': 1000081, 'name': 'B.O.B Control/X-Bow', 'type': 'Building'},
          {'id': 1000082, 'name': 'Healing Hut', 'type': 'Building'},
          {'id': 1000084, 'name': 'Multi-Archer Tower', 'type': 'Building'},
          {'id': 1000085, 'name': 'Ricochet Cannon', 'type': 'Building'},
          {'id': 1000089, 'name': 'Firespitter', 'type': 'Building'},
          {'id': 1000093, 'name': 'Helper Hut', 'type': 'Building'},
          {'id': 4000000, 'name': 'Barbarian', 'type': 'Army'},
          {'id': 4000001, 'name': 'Archer', 'type': 'Army'},
          {'id': 4000002, 'name': 'Goblin', 'type': 'Army'},
          {'id': 4000003, 'name': 'Giant', 'type': 'Army'},
          {'id': 4000004, 'name': 'Wall Breaker', 'type': 'Army'},
          {'id': 4000005, 'name': 'Balloon', 'type': 'Army'},
          {'id': 4000006, 'name': 'Wizard', 'type': 'Army'},
          {'id': 4000007, 'name': 'Healer', 'type': 'Army'},
          {'id': 4000008, 'name': 'Dragon', 'type': 'Army'},
          {'id': 4000009, 'name': 'P.E.K.K.A', 'type': 'Army'},
          {'id': 4000010, 'name': 'Minion', 'type': 'Army'},
          {'id': 4000011, 'name': 'Hog Rider', 'type': 'Army'},
          {'id': 4000012, 'name': 'Valkyrie', 'type': 'Army'},
          {'id': 4000013, 'name': 'Golem', 'type': 'Army'},
          {'id': 4000015, 'name': 'Witch', 'type': 'Army'},
          {'id': 4000017, 'name': 'Lava Hound', 'type': 'Army'},
          {'id': 4000022, 'name': 'Bowler', 'type': 'Army'},
          {'id': 4000023, 'name': 'Baby Dragon', 'type': 'Army'},
          {'id': 4000024, 'name': 'Miner', 'type': 'Army'},
          {'id': 4000031, 'name': 'Super Barbarian', 'type': 'Army'},
          {'id': 4000032, 'name': 'Sneaky Archer', 'type': 'Army'},
          {'id': 4000033, 'name': 'Beta Minion', 'type': 'Army'},
          {'id': 4000034, 'name': 'Boxer Giant', 'type': 'Army'},
          {'id': 4000035, 'name': 'Bomber', 'type': 'Army'},
          {'id': 4000036, 'name': 'Power P.E.K.K.A', 'type': 'Army'},
          {'id': 4000037, 'name': 'Cannon Cart', 'type': 'Army'},
          {'id': 4000038, 'name': 'Drop Ship', 'type': 'Army'},
          {'id': 4000041, 'name': 'Baby Dragon', 'type': 'Army'},
          {'id': 4000042, 'name': 'Night Witch', 'type': 'Army'},
          {'id': 4000051, 'name': 'Wall Wrecker', 'type': 'Army'},
          {'id': 4000052, 'name': 'Battle Blimp', 'type': 'Army'},
          {'id': 4000053, 'name': 'Yeti', 'type': 'Army'},
          {'id': 4000058, 'name': 'Ice Golem', 'type': 'Army'},
          {'id': 4000059, 'name': 'Electro Dragon', 'type': 'Army'},
          {'id': 4000062, 'name': 'Stone Slammer', 'type': 'Army'},
          {'id': 4000065, 'name': 'Dragon Rider', 'type': 'Army'},
          {'id': 4000070, 'name': 'Hog Glider/Wizard', 'type': 'Army'},
          {'id': 4000075, 'name': 'Siege Barracks', 'type': 'Army'},
          {'id': 4000082, 'name': 'Head Hunter', 'type': 'Army'},
          {'id': 4000087, 'name': 'Log Launcher', 'type': 'Army'},
          {'id': 4000091, 'name': 'Flame Flinger', 'type': 'Army'},
          {'id': 4000092, 'name': 'Battle Drill', 'type': 'Army'},
          {'id': 4000095, 'name': 'Electro Titan', 'type': 'Army'},
          {'id': 4000097, 'name': 'Apprentice Warden', 'type': 'Army'},
          {'id': 4000106, 'name': 'Hog Glider/Wizard', 'type': 'Army'},
          {'id': 4000110, 'name': 'Root Rider', 'type': 'Army'},
          {'id': 4000123, 'name': 'Druid', 'type': 'Army'},
          {'id': 4000132, 'name': 'Thrower', 'type': 'Army'},
          {'id': 12000000, 'name': 'Bomb', 'type': 'Building'},
          {'id': 12000001, 'name': 'Spring Trap', 'type': 'Building'},
          {'id': 12000002, 'name': 'Giant Bomb', 'type': 'Building'},
          {'id': 12000005, 'name': 'Air Bomb', 'type': 'Building'},
          {'id': 12000006, 'name': 'Seeking Air Mine', 'type': 'Building'},
          {'id': 12000008, 'name': 'Skeleton Trap', 'type': 'Building'},
          {'id': 12000010, 'name': 'Spring Trap', 'type': 'Building'},
          {'id': 12000011, 'name': 'Push Trap', 'type': 'Building'},
          {'id': 12000013, 'name': 'Mine', 'type': 'Building'},
          {'id': 12000014, 'name': 'Mega Mine', 'type': 'Building'},
          {'id': 12000016, 'name': 'Tornado Trap', 'type': 'Building'},
          {'id': 26000000, 'name': 'Lightning Spell', 'type': 'Army'},
          {'id': 26000001, 'name': 'Healing Spell', 'type': 'Army'},
          {'id': 26000002, 'name': 'Rage Spell', 'type': 'Army'},
          {'id': 26000003, 'name': 'Jump Spell', 'type': 'Army'},
          {'id': 26000005, 'name': 'Freeze Spell', 'type': 'Army'},
          {'id': 26000009, 'name': 'Poison Spell', 'type': 'Army'},
          {'id': 26000010, 'name': 'Earthquake Spell', 'type': 'Army'},
          {'id': 26000011, 'name': 'Haste Spell', 'type': 'Army'},
          {'id': 26000016, 'name': 'Clone Spell', 'type': 'Army'},
          {'id': 26000017, 'name': 'Skeleton Spell', 'type': 'Army'},
          {'id': 26000028, 'name': 'Bat Spell', 'type': 'Army'},
          {'id': 26000035, 'name': 'Invisibility Spell', 'type': 'Army'},
          {'id': 26000053, 'name': 'Recall Spell', 'type': 'Army'},
          {'id': 26000070, 'name': 'Overgrowth Spell', 'type': 'Army'},
          {'id': 26000098, 'name': 'Revive Spell', 'type': 'Army'},
          {'id': 28000000, 'name': 'Barbarian King', 'type': 'Building'},
          {'id': 28000001, 'name': 'Archer Queen', 'type': 'Building'},
          {'id': 28000002, 'name': 'Grand Warden', 'type': 'Building'},
          {'id': 28000003, 'name': 'Battle Machine', 'type': 'Building'},
          {'id': 28000004, 'name': 'Royal Champion', 'type': 'Building'},
          {'id': 28000005, 'name': 'Battle Copter', 'type': 'Building'},
          {'id': 28000006, 'name': 'Minion Prince', 'type': 'Building'},
          {'id': 73000000, 'name': 'L.A.S.S.I.', 'type': 'Pet'},
          {'id': 73000001, 'name': 'Mighty Yak', 'type': 'Pet'},
          {'id': 73000002, 'name': 'Electro Owl', 'type': 'Pet'},
          {'id': 73000003, 'name': 'Unicorn', 'type': 'Pet'},
          {'id': 73000004, 'name': 'Phoenix', 'type': 'Pet'},
          {'id': 73000007, 'name': 'Poison Lizard', 'type': 'Pet'},
          {'id': 73000008, 'name': 'Diggy', 'type': 'Pet'},
          {'id': 73000009, 'name': 'Frosty', 'type': 'Pet'},
          {'id': 73000010, 'name': 'Spirit Fox', 'type': 'Pet'},
          {'id': 73000011, 'name': 'Angry Jelly', 'type': 'Pet'},
          {'id': 73000016, 'name': 'Sneezy', 'type': 'Pet'},
        ];

        for (final u in upgrades) {
          batch.insert(
            tableNameUpgrades,
            {
              'UpgradeId': u['id'],
              'UpgradeName': u['name'],
              'UpgradeType': u['type'],
            },
          );
        }

        await batch.commit(noResult: true);
      },
    );
  }

  Future<void> insertTimer(TimerModel timer) async {
    final db = await database;
    timer.timerId = await db.insert('timers', timer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Schedule notification after inserting
    await _scheduleNotification(timer);
  }

  Future<List<TimerModel>> getTimers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableNameTimers);
    return List.generate(maps.length, (i) => TimerModel.fromMap(maps[i]));
  }

  Future<void> deleteTimer(int? id) async {
    if (id != null) {
      final db = await database;
      await db.delete(tableNameTimers, where: 'TimerId = ?', whereArgs: [id]);

      await notificationsPlugin.cancel(id);
    }
  }

  Future<void> deleteTimersForPlayer(String player) async {
    final db = await database;

    final timers = List<Map<String, dynamic>>.from(
      await db.query(
        tableNameTimers,
        where: 'Player = ?',
        whereArgs: [player],
      ),
    );

    for (final timer in timers) {
      final int? id = timer['TimerId'] as int?;

      if (id != null) {
        await notificationsPlugin.cancel(id);

        await db.delete(
          tableNameTimers,
          where: 'TimerId = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Future<String?> getUpgradeName(int upgradeId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      tableNameUpgrades,
      columns: ['UpgradeName'],
      where: 'UpgradeId = ?',
      whereArgs: [upgradeId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['UpgradeName'] as String;
    }
    return null;
  }


  Future<void> updateTimer(TimerModel timer) async {
    final db = await database;
    await db.update(
      'timers',
      timer.toMap(),
      where: 'id = ?',
      whereArgs: [timer.timerId],
    );
  }
  
  Future<String?> getUpgradeTypeFromUpgradeId(int? upgradeId) async {
    final db = await database;

    // Query the 'upgrades' table to get the UpgradeTypeId for the given UpgradeId
    final List<Map<String, dynamic>> result = await db.query(
      tableNameUpgrades,
      columns: ['UpgradeType'], // Assuming 'UpgradeType' is the column name
      where: 'UpgradeId = ?',
      whereArgs: [upgradeId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final String upgradeType = result.first['UpgradeType'] as String;
      return upgradeType;
    }

    return null; // Return null if no matching UpgradeId is found
  }

  Future<void> _scheduleNotification(TimerModel timer) async {
    String upgradeMessage;
    if (timer.timerName == 'Helpers Ready') {
      upgradeMessage = 'Helpers are ready for action';
    } else if (timer.timerName == 'Clock Tower Boost Ready') {
      upgradeMessage = 'Clock Tower Boost is ready';
    } else {
      upgradeMessage = '${timer.timerName} has finished upgrading.';
    }

    await notificationsPlugin.zonedSchedule(
      timer.timerId!,
      timer.player,
      upgradeMessage,
      tz.TZDateTime.from(timer.readyDateTime, tz.local),
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
