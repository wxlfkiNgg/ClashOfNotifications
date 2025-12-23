import 'dart:ffi';

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

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await notificationsPlugin.initialize(initializationSettings);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Australia/Brisbane'));

  // Force Portrait Mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Normal Portrait
  ]);

  runApp(const MyApp());
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
          titleTextStyle: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold),
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
  final List<String> upgradeTypes = ['Building', 'Army', 'Hero', 'Pet', 'Alert'];
  final List<String> players = ['The Wolf', 'Splyce', 'P.L.U.C.K.', 'The Big Fella'];

  List<TimerModel> timers = [];
  late DatabaseHelper dbHelper;
  Timer? _timer;
  String displayMode = 'Timer';

  // State variables for the selected filters
  List<String> selectedVillageTypes = [];
  List<String> selectedUpgradeTypes = [];
  List<String> selectedPlayers = [];

  // Method to request notification permission
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

  Future<bool> _uploadFromClipboard() async {
    final clipboardText = await _getClipboardData();

    if (clipboardText == null || clipboardText.isEmpty) {
      return false;
    }

    final isValid = await _validateClipboardData(clipboardText);

    if (isValid) {
      final Map<String, dynamic> village = jsonDecode(clipboardText);

      final String player = _getPlayerNameFromTag(village['tag']);
      await dbHelper.deleteTimersForPlayer(player);

      final timers = await _extractUpgradingItems(village, dbHelper);

      for (final t in timers) {
        final newTimer = TimerModel(
          player: t['player'],
          villageType: t['villageType'],
          upgradeId: t['upgradeId'],
          timerName: t['timerName'] ?? "unknown_${t['upgradeId']}",
          upgradeType: t['upgradeType'],
          readyDateTime: t['readyDateTime'],
        );

        await dbHelper.insertTimer(newTimer);
      }

      _loadTimers();
      return true;
    }
    else {
      return false;
    }
  }

  String _getPlayerNameFromTag(String tag) {
    if (tag == "#Q0YY0CR0") {
      return "The Wolf";
    } else if (tag == "#GRJLG0RR0") {
      return "Splyce";
    } else if (tag == "#GQUV2JRY2") {
      return "P.L.U.C.K.";
    } else if (tag == "#GJ9UCCG8J") {
      return "Joe";
    } else if (tag == "#GVLPGGQ2G") {
      return "Bruce 2";
    } else if (tag == "#GCRY889L9") {
      return "Bruce 3";
    } else if (tag == "#GJUGPPRY2") {
      return "Bruce 4";
    } else if (tag == "#GUV22LQPP") {
      return "Bruce 5";
    } else {
      return "Unknown: $tag";
    }
  }

  Future<bool> _validateClipboardData(String clipboardData) async {
    if (clipboardData.isEmpty) return false;

    try {
      final parsed = jsonDecode(clipboardData);

      // Top-level must be a Map
      if (parsed is! Map<String, dynamic>) return false;

      // Required keys
      final requiredKeys = ["tag", "timestamp", "buildings"];
      for (var key in requiredKeys) {
        if (!parsed.containsKey(key)) return false;
      }

      // Basic type checks
      if (parsed["tag"] is! String) return false;
      if (parsed["timestamp"] is! int) return false;
      if (parsed["buildings"] is! List) return false;

      // Quick validation of at least one building entry
      if ((parsed["buildings"] as List).isNotEmpty) {
        final firstBuilding = (parsed["buildings"] as List).first;
        if (firstBuilding is! Map) return false;
        if (!firstBuilding.containsKey("data") || !firstBuilding.containsKey("lvl")) {
          return false;
        }
      }

      return true;
    } catch (e) {
      // jsonDecode failed or validation failed
      return false;
    }
  }

  Future<Map<String, String>> _loadMapping(String filename) async {
    final String jsonString = await rootBundle.loadString('assets/clashdata/$filename');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<List<Map<String, dynamic>>> _extractUpgradingItems(
    Map<String, dynamic> village,
    DatabaseHelper dbHelper,
  ) async {
    final List<Map<String, dynamic>> upgradingItems = [];
      final int timestamp = village['timestamp'];
      final DateTime exportTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000); 
      
    final sections = [
      "helpers",
      "buildings",
      "traps",
      "units",
      "siege_machines",
      "heroes",
      "spells",
      "pets",
      "buildings2",
      "traps2",
      "units2",
      "heroes2",
      "boosts",
    ];

    for (final section in sections) {
      if (village.containsKey(section) && village[section] is List) {
        if (section == "helpers") {
          for (final item in village[section]) {
            if (item is Map && item.containsKey("helper_cooldown")) {
              Duration duration = Duration(seconds: item["helper_cooldown"]);
              final readyDateTime = exportTime.add(duration);

              upgradingItems.add({
                'player': _getPlayerNameFromTag(village['tag']),
                'villageType': 'Home Village',
                'upgradeId': null,
                'timerName': "Helpers Ready",
                'nextUpgrade': null,
                'upgradeType': "Alert",
                'readyDateTime': readyDateTime,
              });

              break;
            }
          }
        } else {
          for (final item in village[section]) {
            if (item is Map && item.containsKey("timer")) {
              final String idStr = item["data"].toString();
              final int? upgradeId = int.tryParse(idStr);
              final int? helperTimerSeconds = item.containsKey("helper_timer") ? item["helper_timer"] : null;

              final String player = _getPlayerNameFromTag(village['tag']);
              final String villageType = (section.endsWith("2")) ? 'Builder Base' : 'Home Village';
              final String upgradeType;

              if (section.contains("buildings") || section.contains("traps") || section.contains("heroes")) {
                upgradeType = "Building";
              } else if (section.contains("units") || section.contains("siege_machines") || section.contains("spells")) {
                upgradeType = "Army";
              } else if (section.startsWith("pets")) {
                upgradeType = "Pet";
              } else {
                upgradeType = "Unknown";
              }

              // Fetch name from database
              final upgradeName = upgradeId != null
                  ? await dbHelper.getUpgradeName(upgradeId)
                  : null;

              Duration duration = Duration(seconds: item["timer"]);
              final readyDateTime = exportTime.add(duration); 

              // Get the actual ready time with relevant boosts applied
              final DateTime processedReadyDateTime = await _processUpgradeDateTime(
                villageType,
                upgradeId,
                exportTime,
                readyDateTime,
                village,
                helperTimerSeconds,
              );

              upgradingItems.add({
                'player': player,
                'villageType': villageType,
                'upgradeId': upgradeId,
                'timerName': upgradeName,
                'nextUpgrade': null,
                'upgradeType': upgradeType,
                'readyDateTime': processedReadyDateTime,
              });
            }
          }
        }
      } else if (village.containsKey(section) && section == "boosts") {
        if (village[section] is Map && village[section].containsKey("clocktower_cooldown")) {
          final String player = _getPlayerNameFromTag(village['tag']);

          Duration duration = Duration(seconds: village[section]["clocktower_cooldown"]);
          final readyDateTime = exportTime.add(duration);

          upgradingItems.add({
            'player': player,
            'villageType': "Builder Base",
            'upgradeId': null,
            'timerName': "Clock Tower Boost Ready",
            'nextUpgrade': null,
            'upgradeType': "Alert",
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
    // Await the asynchronous database call
    final String? upgradeType = await dbHelper.getUpgradeTypeFromUpgradeId(upgradeId);
    double remainingSeconds = readyDateTime.difference(effectiveDateTime).inSeconds.toDouble();

    if (remainingSeconds <= 0) {
      return effectiveDateTime; // Already completed
    }

    // Hardcoded boosts and their properties (replace with dynamic data if needed)
    final List<Map<String, dynamic>> activeBoosts = [];

    // Extract boosts from the JSON
    if (villageData.containsKey('boosts') && villageData['boosts'] is Map) {
      final Map<String, dynamic> boosts = villageData['boosts'];

      // Hardcoded boost amounts and their affected types
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
          'affectedUpgradeType': null, // Affects all upgrades in Builder Base
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
            'boostAmount': boostInfo['boostAmount'], // Hardcoded boost amount
            'startTime': effectiveDateTime, // Assume the boost starts now
            'endTime': effectiveDateTime.add(Duration(seconds: duration)), // Duration from JSON
            'affectedVillageType': boostInfo['affectedVillageType'], // Village type
            'affectedUpgradeType': boostInfo['affectedUpgradeType'], // Upgrade type
          });
        }
      });
    }

    // Add helper boost if `helper_timer` is provided
    if (helperTimerSeconds != null && helperTimerSeconds > 0) {
      // Step 2: Determine the relevant helper based on the UpgradeTypeId
      final Map<int, String?> helperUpgradeTypeMapping = {
        93000000: "Building", // Builder Apprentice -> Building upgrades
        93000001: "Army", // Lab Assistant -> Army upgrades
      };

      int? relevantHelperId;
      helperUpgradeTypeMapping.forEach((helperId, typeId) {
        if (typeId == upgradeType) {
          relevantHelperId = helperId;
        }
      });

      // Step 3: Get the helper's level from the JSON data
      if (relevantHelperId != null && villageData.containsKey('helpers') && villageData['helpers'] is List) {
        final List<dynamic> helpers = villageData['helpers'];
        for (final helper in helpers) {
          if (helper is Map && helper['data'] == relevantHelperId) {
            final int helperLevel = helper['lvl'];

            // Step 4: Add the helper boost to activeBoosts
            activeBoosts.add({
              'boostName': 'Helper Boost',
              'boostAmount': helperLevel.toDouble() + 1.0, // Use the helper level as the boost amount
              'startTime': effectiveDateTime,
              'endTime': effectiveDateTime.add(Duration(seconds: helperTimerSeconds)),
              'affectedVillageType': villageType,
              'affectedUpgradeType': upgradeType,
            });
            break; // Stop once the relevant helper is found
          }
        }
      }
    }

    // Step 1: Filter boosts relevant to this upgrade
    final List<Map<String, dynamic>> relevantBoosts = activeBoosts.where((boost) {
      final bool villageMatches = boost['affectedVillageType'] == null ||
          boost['affectedVillageType'] == villageType;
      final bool upgradeMatches = boost['affectedUpgradeType'] == null ||
          (upgradeId != null && boost['affectedUpgradeType'] == upgradeType);
      return villageMatches && upgradeMatches;
    }).toList();

    // Step 2: Create a timeline of boost segments
    final List<Map<String, dynamic>> segments = [];
    final List<DateTime> boundaries = relevantBoosts
        .expand((boost) => [boost['startTime'] as DateTime, boost['endTime'] as DateTime])
        .toSet()
        .toList()
      ..sort();

    for (int i = 0; i < boundaries.length - 1; i++) {
      final segmentStart = boundaries[i];
      final segmentEnd = boundaries[i + 1];

      // Calculate the total boost for this segment
      double totalBoost = 0.0; // Default is no boost
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

    // Step 3: Process each segment to calculate the effective upgrade time
    DateTime effectiveTime = effectiveDateTime;

    for (final segment in segments) {
      if (remainingSeconds <= 0) break;

      final segmentStart = segment['startTime'] as DateTime;
      final segmentEnd = segment['endTime'] as DateTime;
      final double boostAmount = segment['boostAmount'] as double;

      final double segmentDuration = segmentEnd.difference(segmentStart).inSeconds.toDouble();

      if (segmentStart.isAfter(effectiveTime)) {
        // Skip segments that are in the past
        continue;
      }

      final double effectiveSegmentDuration = segmentDuration * boostAmount;

      if (effectiveSegmentDuration >= remainingSeconds) {
        // If this segment completes the upgrade
        effectiveTime = effectiveTime.add(Duration(seconds: (remainingSeconds / boostAmount).ceil()));
        remainingSeconds = 0;
      } else {
        // Otherwise, subtract the effective time and move to the next segment
        effectiveTime = segmentEnd;
        remainingSeconds -= effectiveSegmentDuration;
      }
    }

    // Step 4: If there's still time remaining, add it without boosts
    if (remainingSeconds > 0) {
      effectiveTime = effectiveTime.add(Duration(seconds: remainingSeconds.ceil()));
    }

    return effectiveTime;
  }

  Color _getUpgradeTimeColor(DateTime time) {
    final hour = time.hour;
    if (time.isBefore(DateTime.now())) {
      return Colors.green; // Already done
    }

    // Determine the color based on the target hour
    if (hour >= 23 || hour < 6) {
      return Colors.red; // Between 11 PM and 6 AM
    } else if (hour >= 6 && hour < 7) {
      return Colors.orange; // Between 6 AM and 7 AM
    } else if (hour >= 7 && hour < 8) {
      return Colors.yellow; // Between 7 AM and 8 AM
    } else {
      return Colors.white; // Otherwise (anything else)
    }
  }

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _requestNotificationPermission();
    _loadTimers(); // Initial load of timers
    _startTimer();
  }

  // Method to load timers from the database
  Future<void> _loadTimers() async {
    final loadedTimers = await dbHelper.getTimers();

    // Apply filtering based on selected filters
    final filteredTimers = loadedTimers.where((timer) {
      bool matchesPlayer = selectedPlayers.isEmpty || selectedPlayers.contains(timer.player);
      bool matchesVillageType = selectedVillageTypes.isEmpty || selectedVillageTypes.contains(timer.villageType);
      bool matchesUpgradeType = selectedUpgradeTypes.isEmpty || selectedUpgradeTypes.contains(timer.upgradeType);
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
      return "Done!";
    } else {
      if (displayMode == "Timer") {
        if (days == 0) {
          if (hours == 0) {
            return "${minutes}m ${seconds}s";
          } else {
            return "${hours}h ${minutes}m";
          }
        } else {
          return "${days}d ${hours}h ${minutes}m";
        }
      } 
      else if (displayMode == "Date") {
        final DateTime now = DateTime.now();
        final DateTime expiryDate = now.add(duration);
        final timeFormat = DateFormat('h:mm a'); // 12-hour format with AM/PM

        final DateTime todayDate = DateTime(now.year, now.month, now.day);
        final DateTime tomorrowDate = todayDate.add(const Duration(days: 1));
        final DateTime expiryDateOnly = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

        if (expiryDateOnly == todayDate) {
          return timeFormat.format(expiryDate);
        } else if (expiryDateOnly == tomorrowDate) {
          return "Tomorrow - ${timeFormat.format(expiryDate)}";
        } else {
          final dateFormat = DateFormat('E, d MMM');
          return "${dateFormat.format(expiryDate)} ${timeFormat.format(expiryDate)}";
        }
      } 
      else {
        return "";
      }
    }
  }

  // Show Player filter dialog
  Future<void> _showFilterDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121), // Dark background
          title: const Text(
            "Filters",
            style: TextStyle(color: Colors.greenAccent, fontSize: 16),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Player Filters
                    const Text("Players", style: TextStyle(color: Colors.white)),
                    ...players.map((player) {
                      return CheckboxListTile(
                        title: Text(player, style: const TextStyle(color: Colors.white)),
                        value: selectedPlayers.contains(player),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected != null) {
                              if (selected) {
                                selectedPlayers.add(player);
                              } else {
                                selectedPlayers.remove(player);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                    const Divider(color: Colors.white70),
                    // Village Type Filters
                    const Text("Village Types", style: TextStyle(color: Colors.white)),
                    ...villageTypes.map((villageType) {
                      return CheckboxListTile(
                        title: Text(villageType, style: const TextStyle(color: Colors.white)),
                        value: selectedVillageTypes.contains(villageType),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected != null) {
                              if (selected) {
                                selectedVillageTypes.add(villageType);
                              } else {
                                selectedVillageTypes.remove(villageType);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                    const Divider(color: Colors.white70),
                    // Village Type Filters
                    const Text("Upgrade Types", style: TextStyle(color: Colors.white)),
                    ...upgradeTypes.map((upgradType) {
                      return CheckboxListTile(
                        title: Text(upgradType, style: const TextStyle(color: Colors.white)),
                        value: selectedUpgradeTypes.contains(upgradType),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected != null) {
                              if (selected) {
                                selectedUpgradeTypes.add(upgradType);
                              } else {
                                selectedUpgradeTypes.remove(upgradType);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _loadTimers(); // Reload timers with applied filters
                Navigator.pop(context);
              },
              child: const Text("Apply", style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without applying filters
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
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
            backgroundColor: const Color(0xFF212121), // Dark grey
            title: const Text(
              "Delete Timer?",
              style: TextStyle(color: Color(0xFFF5F5F5)), // White
            ),
            content: const Text(
              "Are you sure you want to delete this timer?",
              style: TextStyle(color: Color(0xFFF5F5F5)), // White
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFFBDBDBD))), // Medium grey
              ),
              TextButton(
                onPressed: () {
                  dbHelper.deleteTimer(timerId);
                  _loadTimers(); // Reload timers after deletion
                  Navigator.of(context).pop(true);
                },
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ) ??
      false;
    }
    else {
      return false;
    }
  }

  Color _getVillageIconColour(String? villageType) {
    switch (villageType) {
      case "Home Village":
        return Colors.lightGreenAccent;
      case "Builder Base":
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Color _getUpgradeColour(String? upgradeType) {
    switch (upgradeType) {
      case "Building":
        return Colors.amber;
      case "Army":
        return Colors.purple;
      case "Pet":
        return Colors.deepPurple;
      case "Alert":
        return Colors.lightBlueAccent;
      default:
        return Colors.grey;
    }
  }

  Color _getTimerFontColour(String? upgradeType) {
    switch (upgradeType) {
      case "Alert":
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
    if (player == "The Wolf") {
      return Colors.green;
    } else if (player == "Splyce") {
      return Colors.blueAccent;
    } else if (player == "The Big Fella") { 
      return Colors.green;
    } else if (player == "P.L.U.C.K.") {
      return Colors.deepOrangeAccent;
    } else {
      return Colors.grey;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Timers"),
        actions: [
          // Toggle for Timer/Date View
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () async {
              setState(() {
                displayMode = displayMode == "Timer" ? "Date" : "Timer";
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
            tooltip: "Clear Filters",
            onPressed: _resetFilters,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: timers.length,
        itemBuilder: (context, index) {
          final timer = timers[index];

          // Apply player and village type filters
          if (selectedPlayers.isNotEmpty && !selectedPlayers.contains(timer.player)) {
            return const SizedBox.shrink(); // Skip this item if it doesn't match the player filter
          }
          if (selectedVillageTypes.isNotEmpty && !selectedVillageTypes.contains(timer.villageType)) {
            return const SizedBox.shrink(); // Skip this item if it doesn't match the village type filter
          }

          // Extract data for the current item
          final String player = timer.player;
          final String? villageType = timer.villageType;
          final String? upgradeType = timer.upgradeType;
          final String timerName = timer.timerName;
          final DateTime readyDateTime = timer.readyDateTime;

          // Determine icons or indicators for village and upgrade type
          final IconData villageIcon = villageType == 'Builder Base'
              ? Icons.construction // Example icon for Builder Base
              : Icons.home; // Example icon for Home Village

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

          final String timeDisplay = _formatDuration(readyDateTime.difference(DateTime.now()));

          return GestureDetector(
            onLongPress: () async {
             await _confirmDelete(context, timer.timerId);
            },
            child: Card(
              color: const Color(0xFF212121),
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 1.0),
              child: ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(villageIcon, color: _getVillageIconColour(villageType)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeDisplay,
                    style: TextStyle(
                      color: _getUpgradeTimeColor(readyDateTime),
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
          String test = _formatDuration(const Duration(hours: 24));

          final bool confirmed = await _uploadFromClipboard();
          if (confirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Data uploaded successfully - good job kiddo")),
            );
          } else {    
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Data is not in the expected format - copy the shit again mate.")),
            );
          }
        },
        child: const Icon(Icons.upload_file),
        tooltip: "Upload Data",
      ),
    );
  }
}
