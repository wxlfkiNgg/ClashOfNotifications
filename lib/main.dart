import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:clashofnotifications/models/timer_model.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:clashofnotifications/models/time_colour_period_model.dart';
import 'package:clashofnotifications/models/player_model.dart';
import 'package:clashofnotifications/pages/settings_page.dart';

void main() async {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  notificationsPlugin.initialize(
      settings: initializationSettings,
    );

  tz.initializeTimeZones();
  tz.setLocalLocation(
      tz.getLocation('Australia/Brisbane')); //Daylight saving is for nerds

  // Force portrait orientation - app looks dogshit in landscape and this is easier than fixing
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class _TimerListEntry {
  final TimerModel? timer;
  final DateTime? dateHeader;

  _TimerListEntry.timer(this.timer) : dateHeader = null;
  _TimerListEntry.header(this.dateHeader) : timer = null;

  bool get isHeader => dateHeader != null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          titleTextStyle: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold),
          iconTheme: const IconThemeData(color: Colors.greenAccent),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
          ),
          hintStyle: const TextStyle(color: Colors.white),
          labelStyle: const TextStyle(color: Colors.white),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final List<String> villageTypes = ['Home Village', 'Builder Base'];
  final List<String> upgradeTypes = [
    'Building',
    'Army',
    'Hero',
    'Pet',
    'Alert'
  ];
  List<String> players = []; // Will retrieve from database
  List<PlayerModel> playerModels = [];

  List<TimerModel> timers = [];
  late DatabaseHelper dbHelper;
  Timer? _timer;
  String displayMode = 'Timer';

  List<String> selectedVillageTypes = [];
  List<String> selectedUpgradeTypes = [];
  List<String> selectedPlayers = [];
  List<TimeColourPeriodModel> customTimeColourPeriods = [];

  // Ask for permission (simp) to send notifications if not already approved
  Future<void> _requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<String?> _getClipboardData() async {
    final data = await Clipboard.getData('text/plain');
    return data?.text;
  }

  Future<PlayerModel?> _promptCreatePlayerFromTag(String tag) async {
    final controller = TextEditingController();
    Color selectedColour = Colors.grey;

    return await showDialog<PlayerModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF212121),
              title: const Text('Unknown Player',
                style: TextStyle(color: Colors.greenAccent)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ohi, and who might this be?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Player Name',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ColorPicker(
                    pickerColor: selectedColour,
                    onColorChanged: (colour) {
                      setState(() {
                        selectedColour = colour;
                      });
                    },
                    pickerAreaHeightPercent: 0.8,
                    enableAlpha: false,
                    displayThumbColor: true,
                    labelTypes: [],
                    paletteType: PaletteType.hsvWithHue,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Skip', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(PlayerModel(
                      name: name,
                      tag: tag,
                      colourValue: selectedColour.toARGB32(),
                    ));
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.greenAccent)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _uploadFromClipboard() async {
    final clipboardText = await _getClipboardData() ??
        ''; //For this case we'll just use an empty string (not null) if there's no text retrieved from the clipboard
    final isValid = await _validateTextIsVillageExport(clipboardText);

    if (isValid) {
      final Map<String, dynamic> village = jsonDecode(clipboardText);
      String playerName = _getPlayerNameFromTag(village['tag']);

      PlayerModel? newPlayer;
      if (playerName.startsWith('Unknown: ')) {
        newPlayer = await _promptCreatePlayerFromTag(village['tag']);
        if (newPlayer != null) {
          final existingPlayers = await dbHelper.getPlayers();
          existingPlayers.add(newPlayer);
          await dbHelper.savePlayers(existingPlayers);
          await _loadPlayers();
          playerName = newPlayer.name;
        }
      }

      await dbHelper.deleteTimersForPlayerTag(playerName, village['tag']);

      final List<Map<String, dynamic>> timers =
          await _extractUpgradingItems(village, dbHelper);
      for (final t in timers) {
        final newTimer = TimerModel(
          player: t['player'],
          playerTag: t['playerTag'],
          villageType: t['villageType'],
          upgradeId: t['upgradeId'],
          timerName: t['timerName'] ?? 'unknown_${t['upgradeId']}',
          upgradeType: t['upgradeType'],
          upgradeLevel: t['upgradeLevel'] ?? 0,
          readyDateTime: t['readyDateTime'],
        );

        await dbHelper.insertTimer(newTimer);
      }

      _loadTimers(); //Refresh that shit
    }

    return isValid;
  }

  String _getPlayerNameFromTag(String tag) {
    for (final player in playerModels) {
      if (player.tag == tag) {
        return player.name;
      }
    }
    return 'Unknown: $tag';
  }

  //Super simple check on provided text to check if it's actually a village export
  //This is not the be-all and end-all, but it should catch 99.999999% of uploaded data that isn't a clash village export
  //Also, did you know that 62% of statistics are completely made up?
  Future<bool> _validateTextIsVillageExport(String text) async {
    if (text.isNotEmpty) {
      try {
        final parsed = jsonDecode(
            text); //If the text isn't a json this'll fail. But do not fret, we have a catch here for just such an occasion

        // First make sure the top level is a Map
        if (parsed is! Map<String, dynamic>) {
          return false;
        }

        // Check we have the right keys, we could add more but honestly it seemed redundant beyond these three
        final requiredKeys = ['tag', 'timestamp', 'buildings'];
        for (String key in requiredKeys) {
          if (!parsed.containsKey(key)) {
            return false;
          }
        }

        // Basic data type checks on the aformentioned keys. By this stage we should be gucci but you never know aye
        if (parsed['tag'] is! String ||
            parsed['timestamp'] is! int ||
            parsed['buildings'] is! List) {
          return false;
        }

        // At this point we are being pedantic but we want to make sure the buildings field at least has an entry with the required fields
        if ((parsed['buildings'] as List).isNotEmpty) {
          final firstBuilding = (parsed['buildings'] as List).first;
          if (firstBuilding is! Map || !firstBuilding.containsKey('data')) {
            return false;
          }
        }

        return true;
      } catch (e) {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _extractUpgradingItems(
    Map<String, dynamic> village,
    DatabaseHelper dbHelper,
  ) async {
    final List<Map<String, dynamic>> upgradingItems = [];
    final int timestamp = village['timestamp'];
    final DateTime exportTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final String playerName = _getPlayerNameFromTag(village['tag']);
    final String playerTag = village['tag'];

    final categories = [
      'helpers',
      'guardians',
      'buildings',
      'traps',
      'units',
      'siege_machines',
      'heroes',
      'spells',
      'pets',
      'buildings2',
      'traps2',
      'units2',
      'heroes2',
      'boosts',
    ];

    for (final category in categories) {
      if (village.containsKey(category) && village[category] is List) {
        //Helper cooldowns are handled separately
        if (category == 'helpers') {
          for (final item in village[category]) {
            if (item is Map && item.containsKey('helper_cooldown')) {
              Duration duration = Duration(seconds: item['helper_cooldown']);
              final readyDateTime = exportTime.add(duration);

              upgradingItems.add({
                'player': playerName,
                'playerTag': playerTag,
                'villageType': 'Home Village',
                'upgradeId': null,
                'timerName': 'Helpers Ready',
                'upgradeType': 'Alert',
                'upgradeLevel': null,
                'readyDateTime': readyDateTime,
              });

              break;
            }
          }
        } else {
          for (final item in village[category]) {
            if (item is Map && item.containsKey('timer')) {
              final String idStr = item['data'].toString();
              final int? upgradeId = int.tryParse(idStr);
              final int? helperTimerSeconds = item.containsKey('helper_timer')
                  ? item['helper_timer']
                  : null;

              final String villageType = (category.endsWith('2'))
                  ? 'Builder Base'
                  : 'Home Village'; //Dodgy as fuck I know, with Nooni's help we may overhaul how all this shit works
              final String upgradeType;

              //because fuck builder base right?
              if (playerName == 'The Big Fella' &&
                  villageType == 'Builder Base') {
                break;
              }

              if (category.contains('buildings') ||
                  category.contains('traps') ||
                  category.contains('heroes') ||
                  category.contains('guardians')) {
                upgradeType = 'Building';
              } else if (category.contains('units') ||
                  category.contains('siege_machines') ||
                  category.contains('spells')) {
                upgradeType = 'Army';
              } else if (category.startsWith('pets')) {
                upgradeType = 'Pet';
              } else {
                upgradeType = 'Unknown';
              }

              final upgradeName = upgradeId != null
                  ? await dbHelper.getUpgradeName(upgradeId)
                  : null;
              final upgradeLevel = item['lvl'] + 1;
              Duration duration = Duration(seconds: item['timer']);
              final readyDateTime = exportTime.add(duration);

              // Get the actual ready time with relevant boosts applied
              final DateTime processedReadyDateTime =
                  await _processUpgradeDateTime(
                villageType,
                upgradeId,
                exportTime,
                readyDateTime,
                village,
                helperTimerSeconds,
              );

              upgradingItems.add({
                'player': playerName,
                'playerTag': playerTag,
                'villageType': villageType,
                'upgradeId': upgradeId,
                'timerName': upgradeName,
                'upgradeType': upgradeType,
                'upgradeLevel': upgradeLevel,
                'readyDateTime': processedReadyDateTime,
              });
            }
          }
        }
      } else if (village.containsKey(category) && category == 'boosts') {
        if (village[category] is Map &&
            village[category].containsKey('clocktower_cooldown')) {
          Duration duration =
              Duration(seconds: village[category]['clocktower_cooldown']);
          final readyDateTime = exportTime.add(duration);

          upgradingItems.add({
            'player': playerName,
            'playerTag': playerTag,
            'villageType': 'Builder Base',
            'upgradeId': null,
            'timerName': 'Clock Tower Boost Ready',
            'upgradeType': 'Alert',
            'upgradeLevel': null,
            'readyDateTime': readyDateTime,
          });
        }
      }
    }

    return upgradingItems;
  }

  Future<DateTime> _processUpgradeDateTime(
    String villageType,
    int? upgradeId,
    DateTime effectiveDateTime,
    DateTime readyDateTime,
    Map<String, dynamic> villageData,
    int? helperTimerSeconds,
  ) async {
    final String? upgradeType =
        await dbHelper.getUpgradeTypeFromUpgradeId(upgradeId);
    double remainingSeconds =
        readyDateTime.difference(effectiveDateTime).inSeconds.toDouble();
    final List<Map<String, dynamic>> activeBoosts = [];

    if (remainingSeconds <= 0) {
      return effectiveDateTime;
    }

    if (villageData.containsKey('boosts') && villageData['boosts'] is Map) {
      final Map<String, dynamic> boosts = villageData['boosts'];

      // Hardcoded boost amounts. We'll improve this later, cbf now
      final Map<String, Map<String, dynamic>> boostDetails = {
        'builder_boost': {
          'boostAmount': 10.0,
          'affectedVillageType': 'Home Village',
          'affectedUpgradeType': 'Building',
        },
        'lab_boost': {
          'boostAmount': 24.0,
          'affectedVillageType': 'Home Village',
          'affectedUpgradeType': 'Army',
        },
        'pet_boost': {
          'boostAmount': 24.0,
          'affectedVillageType': 'Home Village',
          'affectedUpgradeType': 'Pet',
        },
        'clocktower_boost': {
          'boostAmount': 10.0,
          'affectedVillageType': 'Builder Base',
          'affectedUpgradeType': null, // Affects all upgrades so we leave null
        },
        'builder_consumable': {
          'boostAmount': 2.0,
          'affectedVillageType': 'Home Village',
          'affectedUpgradeType': 'Building',
        },
        'lab_consumable': {
          'boostAmount': 4.0,
          'affectedVillageType': 'Home Village',
          'affectedUpgradeType': 'Army',
        },
      };

      // Iterate over the boosts in the JSON
      boosts.forEach((boostName, duration) {
        if (boostDetails.containsKey(boostName)) {
          final boostInfo = boostDetails[boostName]!;
          activeBoosts.add({
            'boostName': boostName,
            'boostAmount': boostInfo['boostAmount'],
            'startTime': effectiveDateTime,
            'endTime': effectiveDateTime.add(Duration(seconds: duration)),
            'affectedVillageType': boostInfo['affectedVillageType'],
            'affectedUpgradeType': boostInfo['affectedUpgradeType'],
          });
        }
      });
    }

    // Add helper boost. Dr. Zoidberg: 'Again with the hardcoding'
    if (helperTimerSeconds != null && helperTimerSeconds > 0) {
      final Map<int, String?> helperUpgradeTypeMapping = {
        93000000: 'Building',
        93000001: 'Army',
      };

      int? relevantHelperId;
      helperUpgradeTypeMapping.forEach((helperId, typeId) {
        if (typeId == upgradeType) {
          relevantHelperId = helperId;
        }
      });

      // We grab the level of the helper
      if (relevantHelperId != null &&
          villageData.containsKey('helpers') &&
          villageData['helpers'] is List) {
        final List<dynamic> helpers = villageData['helpers'];
        for (final helper in helpers) {
          if (helper is Map && helper['data'] == relevantHelperId) {
            final int helperLevel = helper['lvl'];

            //Now add to the list of active boosts to apply
            activeBoosts.add({
              'boostName': 'Helper Boost',
              'boostAmount': helperLevel.toDouble() +
                  1.0, // Use the helper level as the boost amount, +1 for offset (level 1 is a 2x boost, 2 is 3x etc.)
              'startTime': effectiveDateTime,
              'endTime':
                  effectiveDateTime.add(Duration(seconds: helperTimerSeconds)),
              'affectedVillageType': villageType,
              'affectedUpgradeType': upgradeType,
            });
            break; // STOP CUNT
          }
        }
      }
    }

    // Filter boosts relevant to this upgrade
    final List<Map<String, dynamic>> relevantBoosts =
        activeBoosts.where((boost) {
      final bool villageMatches = boost['affectedVillageType'] == null ||
          boost['affectedVillageType'] == villageType;
      final bool upgradeMatches = boost['affectedUpgradeType'] == null ||
          (upgradeId != null && boost['affectedUpgradeType'] == upgradeType);
      return villageMatches && upgradeMatches;
    }).toList();

    // Humble brag warning, here is where we get clever with it. We make a 'timeline' of the boosts which accurately track stacked boosts for their respective time period
    final List<Map<String, dynamic>> segments = [];
    final List<DateTime> boundaries = relevantBoosts
        .expand((boost) =>
            [boost['startTime'] as DateTime, boost['endTime'] as DateTime])
        .toSet()
        .toList()
      ..sort();

    for (int i = 0; i < boundaries.length - 1; i++) {
      final segmentStart = boundaries[i];
      final segmentEnd = boundaries[i + 1];

      // Calculate the total boost for this segment
      double totalBoost = 0.0; // Start at 0 obviously
      for (final boost in relevantBoosts) {
        if (segmentStart.isBefore(boost['endTime']) &&
            segmentEnd.isAfter(boost['startTime'])) {
          totalBoost += boost['boostAmount'];
        }
      }

      segments.add({
        'startTime': segmentStart,
        'endTime': segmentEnd,
        'boostAmount': totalBoost,
      });
    }

    // Now process each segment to calculate the effective upgrade time
    DateTime effectiveTime = effectiveDateTime;

    for (final segment in segments) {
      if (remainingSeconds <= 0) break;

      final segmentStart = segment['startTime'] as DateTime;
      final segmentEnd = segment['endTime'] as DateTime;
      final double boostAmount = segment['boostAmount'] as double;

      final double segmentDuration =
          segmentEnd.difference(segmentStart).inSeconds.toDouble();

      if (segmentStart.isAfter(effectiveTime)) {
        // Skip segments that are in the past
        continue;
      }

      final double effectiveSegmentDuration = segmentDuration * boostAmount;

      // If this segment completes the upgrade then we have our result, otherwise subtract the effective time and move on to next segment
      if (effectiveSegmentDuration >= remainingSeconds) {
        effectiveTime = effectiveTime
            .add(Duration(seconds: (remainingSeconds / boostAmount).ceil()));
        remainingSeconds = 0;
      } else {
        // Otherwise, subtract the effective time and move to the next segment
        effectiveTime = segmentEnd;
        remainingSeconds -= effectiveSegmentDuration;
      }
    }

    // Any left over time is added as per normal
    if (remainingSeconds > 0) {
      effectiveTime =
          effectiveTime.add(Duration(seconds: remainingSeconds.ceil()));
    }

    return effectiveTime;
  }

  Color _getUpgradeTimeColour(DateTime time) {
    final hour = time.hour;
    if (time.isBefore(DateTime.now())) {
      return Colors.green; // Already done, trumps all following checks
    }

    if (customTimeColourPeriods.isEmpty) {
      // Do default colours if no custom ones are defined
      if (hour >= 23 || hour < 6) {
        return Colors.red; // 11 PM and 6 AM
      } else if (hour >= 6 && hour < 7) {
        return Colors.orange; // 6 AM and 7 AM
      } else if (hour >= 7 && hour < 8) {
        return Colors.yellow; // 7 AM and 8 AM
      } else {
        return Colors.white;
      }
    } else {
      for (final period in customTimeColourPeriods) {
        if (period.matches(hour)) {
          return Color(period.colourValue);
        }
      }
      return Colors.white;
    }
  }

  Future<void> _loadUserTimeColourPeriods() async {
    final periods = await dbHelper.getTimeColourPeriods();
    setState(() {
      customTimeColourPeriods = periods;
    });
  }

  Future<void> _loadPlayers() async {
    final loadedPlayers = await dbHelper.getPlayers();
    playerModels = loadedPlayers;
    setState(() {
      players = playerModels.map((p) => p.name).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _requestNotificationPermission();
    _loadTimers(); // Initial load of timers
    _startTimer(); // Keep them refreshing
    _loadUserTimeColourPeriods();
    _loadPlayers();
  }

  Future<void> _loadTimers() async {
    final loadedTimers = await dbHelper.getTimers();

    final filteredTimers = loadedTimers.where((timer) {
      bool matchesPlayer =
          selectedPlayers.isEmpty || selectedPlayers.contains(timer.player);
      bool matchesVillageType = selectedVillageTypes.isEmpty ||
          selectedVillageTypes.contains(timer.villageType);
      bool matchesUpgradeType = selectedUpgradeTypes.isEmpty ||
          selectedUpgradeTypes.contains(timer.upgradeType);
      return matchesPlayer && matchesVillageType && matchesUpgradeType;
    }).toList();

    filteredTimers.sort((a, b) => a.readyDateTime.compareTo(b.readyDateTime));

    setState(() {
      timers = filteredTimers;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        //Keeps the timer in the UI updating every cute lil second
      });
    });
  }

  String _formatDuration(Duration duration) {
    int days = duration.inDays;
    int hours = duration.inHours.remainder(24);
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    if (duration.isNegative || duration == Duration.zero) {
      return 'Done!';
    } else {
      if (displayMode == 'Timer') {
        if (days == 0) {
          if (hours == 0) {
            return '${minutes}m ${seconds}s';
          } else {
            return '${hours}h ${minutes}m';
          }
        } else {
          return '${days}d ${hours}h ${minutes}m';
        }
      } else if (displayMode == 'Date') {
        final DateTime now = DateTime.now();
        final DateTime expiryDate = now.add(duration);
        final timeFormat = DateFormat('h:mm a'); // 12-hour format with AM/PM

        return timeFormat.format(expiryDate);
      } else {
        return '';
      }
    }
  }

  String _dateHeaderLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime todayDate = DateTime(now.year, now.month, now.day);
    final DateTime tomorrowDate = todayDate.add(const Duration(days: 1));

    if (date == todayDate) {
      return 'Today';
    } else if (date == tomorrowDate) {
      return 'Tomorrow';
    }

    return DateFormat('EEEE, d MMM').format(date);
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[700], thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              _dateHeaderLabel(date),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[700], thickness: 1)),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text(
            'Filters',
            style: TextStyle(color: Colors.greenAccent, fontSize: 16),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Players',
                        style: TextStyle(color: Colors.white)),
                    ...players.map((player) {
                      return ListTile(
                        title: Text(player,
                            style: const TextStyle(color: Colors.white)),
                        selected: selectedPlayers.contains(player),
                        onTap: () {
                          setState(() {
                            selectedPlayers.clear();
                            selectedVillageTypes.clear();
                            selectedUpgradeTypes.clear();

                            selectedPlayers.add(player);
                            selectedVillageTypes.add('Home Village');
                            selectedUpgradeTypes.add('Building');

                            _loadTimers();
                            Navigator.pop(context);
                          });
                        },
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _loadTimers();
                Navigator.pop(context);
              },
              child: const Text('Apply', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, int? timerId) async {
    if (timerId != null) {
      return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF212121),
                title: const Text(
                  'Delete Timer?',
                  style: TextStyle(color: Color(0xFFF5F5F5)),
                ),
                content: const Text(
                  'Are you sure you want to delete this timer?',
                  style: TextStyle(color: Color(0xFFF5F5F5)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFFBDBDBD))),
                  ),
                  TextButton(
                    onPressed: () {
                      dbHelper.deleteTimer(timerId);
                      _loadTimers();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          ) ??
          false;
    } else {
      return false;
    }
  }

  Color _getVillageIconColour(String? villageType) {
    switch (villageType) {
      case 'Home Village':
        return Colors.lightGreenAccent;
      case 'Builder Base':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Color _getUpgradeColour(String? upgradeType) {
    switch (upgradeType) {
      case 'Building':
        return Colors.amber;
      case 'Army':
        return Colors.purple;
      case 'Pet':
        return Colors.deepPurple;
      case 'Alert':
        return Colors.lightBlueAccent;
      default:
        return Colors.grey;
    }
  }

  Color _getTimerFontColour(String? upgradeType) {
    switch (upgradeType) {
      case 'Alert':
        return Colors.blueGrey;
      default:
        return Colors.white;
    }
  }

  void _resetFilters() {
    setState(() {
      selectedPlayers.clear();
      selectedVillageTypes.clear();
      selectedUpgradeTypes.clear();
      _loadTimers();
    });
  }

  Color getPlayerColour(String player) {
    for (final p in playerModels) {
      if (p.name == player) {
        return p.colour;
      }
    }
    return Colors.grey;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Map<String, List<TimerModel>> _groupHelpersByPlayer(
      List<TimerModel> helperTimers) {
    final Map<String, List<TimerModel>> grouped = {};
    for (final timer in helperTimers) {
      final key = timer.player;
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(timer);
    }
    // Sort within each group: helpers first, then others
    grouped.forEach((key, list) {
      list.sort((a, b) {
        if (a.timerName == 'Helpers Ready' && b.timerName != 'Helpers Ready')
          return -1;
        if (a.timerName != 'Helpers Ready' && b.timerName == 'Helpers Ready')
          return 1;
        return 0;
      });
    });
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    // Separate helper timers from regular timers
    List<TimerModel> helperTimers =
        timers.where((t) => t.upgradeType == 'Alert').toList();
    List<TimerModel> regularTimers =
        timers.where((t) => t.upgradeType != 'Alert').toList();

    // Apply filters to both lists
    if (selectedPlayers.isNotEmpty) {
      helperTimers = helperTimers
          .where((t) => selectedPlayers.contains(t.player))
          .toList();
      regularTimers = regularTimers
          .where((t) => selectedPlayers.contains(t.player))
          .toList();
    }
    if (selectedVillageTypes.isNotEmpty) {
      helperTimers = helperTimers
          .where((t) => selectedVillageTypes.contains(t.villageType))
          .toList();
      regularTimers = regularTimers
          .where((t) => selectedVillageTypes.contains(t.villageType))
          .toList();
    }

    final groupedHelpers = _groupHelpersByPlayer(helperTimers);
    final bool hasHelperTimers = groupedHelpers.isNotEmpty;
    final bool singleHelperPlayer = groupedHelpers.length == 1;

    final List<_TimerListEntry> timerEntries = [];
    DateTime? lastDate;
    final DateTime todayDateOnly = DateTime.now();
    final DateTime todayDate =
        DateTime(todayDateOnly.year, todayDateOnly.month, todayDateOnly.day);
    for (final timer in regularTimers) {
      final DateTime timerDateOnly = DateTime(timer.readyDateTime.year,
          timer.readyDateTime.month, timer.readyDateTime.day);

      if (lastDate == null) {
        if (timerDateOnly != todayDate) {
          timerEntries.add(_TimerListEntry.header(timerDateOnly));
        }
      } else if (timerDateOnly != lastDate) {
        timerEntries.add(_TimerListEntry.header(timerDateOnly));
      }

      timerEntries.add(_TimerListEntry.timer(timer));
      lastDate = timerDateOnly;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timers'),
        actions: [
          // Toggle for Timer/Date View
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SettingsPage(dbHelper: dbHelper),
              ));
              _loadUserTimeColourPeriods();
              _loadPlayers();
              _loadTimers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () async {
              setState(() {
                displayMode = displayMode == 'Timer'
                    ? 'Date'
                    : 'Timer'; // god this line is elegant
              });
            },
          ),
          // Filter Button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          // Clear Filters Button
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Filters',
            onPressed: _resetFilters,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: timerEntries.length + (hasHelperTimers ? 1 : 0),
        itemBuilder: (context, index) {
          if (hasHelperTimers && index == 0) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groupedHelpers.entries.map((entry) {
                      final groupKey = entry.key;
                      final groupTimers = entry.value;
                      return Container(
                        width: singleHelperPlayer ? null : 90,
                        margin: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!singleHelperPlayer) ...[
                              Text(
                                groupKey,
                                style: TextStyle(
                                  color: getPlayerColour(groupKey),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                            singleHelperPlayer
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: groupTimers.map((timer) {
                                      final String timeDisplay =
                                          _formatDuration(timer.readyDateTime
                                              .difference(DateTime.now()));
                                      final IconData alertIcon =
                                          timer.timerName == 'Helpers Ready'
                                              ? Icons.person_outline
                                              : Icons.timer;

                                      return GestureDetector(
                                        onLongPress: () async {
                                          await _confirmDelete(
                                              context, timer.timerId);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 2),
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF212121),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(alertIcon,
                                                  color: _getVillageIconColour(
                                                      timer.villageType),
                                                  size: 20),
                                              const SizedBox(height: 2),
                                              Text(
                                                timeDisplay,
                                                style: TextStyle(
                                                  color: _getUpgradeTimeColour(
                                                      timer.readyDateTime),
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: groupTimers.map((timer) {
                                      final String timeDisplay =
                                          _formatDuration(timer.readyDateTime
                                              .difference(DateTime.now()));
                                      final IconData alertIcon =
                                          timer.timerName == 'Helpers Ready'
                                              ? Icons.person_outline
                                              : Icons.timer;

                                      return GestureDetector(
                                        onLongPress: () async {
                                          await _confirmDelete(
                                              context, timer.timerId);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF212121),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(alertIcon,
                                                  color: _getVillageIconColour(
                                                      timer.villageType),
                                                  size: 20),
                                              const SizedBox(height: 2),
                                              Text(
                                                timeDisplay,
                                                style: TextStyle(
                                                  color: _getUpgradeTimeColour(
                                                      timer.readyDateTime),
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          }

          final int regularListIndex = hasHelperTimers ? index - 1 : index;
          final _TimerListEntry entry = timerEntries[regularListIndex];

          if (entry.isHeader) {
            return _buildDateDivider(entry.dateHeader!);
          }

          final TimerModel timer = entry.timer!;

          final String player = timer.player;
          final String? villageType = timer.villageType;
          final String? upgradeType = timer.upgradeType;
          final String timerName = timer.timerName;
          final DateTime readyDateTime = timer.readyDateTime;

          final IconData villageIcon =
              villageType == 'Builder Base' ? Icons.construction : Icons.home;
          final String timeDisplay =
              _formatDuration(readyDateTime.difference(DateTime.now()));
          final IconData upgradeIcon;

          switch (upgradeType) {
            case 'Army':
              upgradeIcon = Icons.shield;
              break;
            case 'Building':
              upgradeIcon = Icons.build;
              break;
            case 'Pet':
              upgradeIcon = Icons.pets;
              break;
            case 'Alert':
              upgradeIcon = Icons.info;
              break;
            default:
              upgradeIcon = Icons.question_mark;
          }

          return GestureDetector(
            onLongPress: () async {
              await _confirmDelete(context, timer.timerId);
            },
            child: Card(
              color: const Color(0xFF212121),
              margin:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 1.0),
              child: ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(villageIcon,
                        color: _getVillageIconColour(villageType)),
                    const SizedBox(height: 8.0),
                    Icon(upgradeIcon, color: _getUpgradeColour(upgradeType)),
                  ],
                ),
                title: Text(
                  player,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getPlayerColour(player),
                  ),
                ),
                subtitle: Text(
                  timerName,
                  style: TextStyle(color: _getTimerFontColour(upgradeType)),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeDisplay,
                    style: TextStyle(
                      color: _getUpgradeTimeColour(readyDateTime),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bool confirmed = await _uploadFromClipboard();
          if (confirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Data uploaded successfully - good job kiddo')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Data is not in the expected format - copy the shit again mate.')),
            );
          }
        },
        tooltip: 'Upload Data',
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
