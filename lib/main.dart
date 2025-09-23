import 'package:clashofnotifications/pages/helpers_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:clashofnotifications/pages/timer_page.dart';
import 'package:clashofnotifications/models/timer_model.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';
import 'package:clashofnotifications/pages/boost_page.dart';
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
  final List<String> players = ['The Wolf', 'Splyce', 'P.L.U.C.K.'];

  List<TimerModel> timers = [];
  late DatabaseHelper dbHelper;
  Timer? _timer;
  String displayMode = 'Timer';

  // State variables for the selected filters
  List<String> selectedVillageTypes = [];
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

  Future<void> _updateUpgradeNameOnly(BuildContext context, int timerId, String oldUpgradeName) async {
    final TextEditingController controller = TextEditingController();
    controller.text = oldUpgradeName;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text(
            "Update Upgrade Name",
            style: TextStyle(color: Color(0xFFF5F5F5)),
            ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Enter new name",
            ),
            
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog without saving
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  dbHelper.updateTimerUpgradeName(timerId, newName);
                }
                Navigator.of(context).pop(); // close dialog after saving
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, int timerId) async {
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

  Future<bool> _confirmUploadFromClipboard(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text(
            "Upload From Clipboard?",
            style: TextStyle(color: Color(0xFFF5F5F5)),
          ),
          content: const Text(
            "Are you sure you want to upload data from the clipboard? Existing timers for the relevant village will be deleted and replaced.",
            style: TextStyle(color: Color(0xFFF5F5F5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFFBDBDBD))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                _uploadFromClipboard();
              },
              child: const Text("Upload", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    ) ??
    false;
  }

  void _uploadFromClipboard() async {
    final clipboardText = await _getClipboardData();

    if (clipboardText == null || clipboardText.isEmpty) return;

    final isValid = await _validateClipboardData(clipboardText);

    if (isValid) {
      final Map<String, dynamic> village = jsonDecode(clipboardText);

      final String player = _getPlayerNameFromTag(village['tag']);
      await dbHelper.deleteTimersForPlayer(player, "Helpers Ready");

      // Load building/unit/hero mappings (can cache these instead of reloading each time)
      final objectMap = await _loadMapping("objects.json");

      final timers = await _extractUpgradingItems(village, objectMap);

      for (final t in timers) {
        //print("⏳ ${t['name']} (lvl ${t['level']}) is upgrading, ${t['remaining']}s left");
        Duration duration = Duration(seconds: t['remaining'] - 3); //3 second buffer to account for export/import time difference
        final expiryTime = DateTime.now().add(duration);

        final newTimer = TimerModel(
          player: player,
          village: 'Home Village',
          upgrade: t['name'],
          expiry: expiryTime,
          isFinished: false,
        );

        await dbHelper.insertTimer(newTimer);
      }
    }
  }


  String _getPlayerNameFromTag(String tag) {
    if (tag == "#Q0YY0CR0") {
      return "The Wolf";
    } else if (tag == "#GRJLG0RR0") {
      return "Splyce";
    } else if (tag == "#GQUV2JRY2") {
      return "P.L.U.C.K.";
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
    Map<String, String> buildingMap,
  ) async {
    final List<Map<String, dynamic>> upgradingItems = [];

    // List of all sections we care about
    final sections = [
      "buildings",
      "heroes",
      "pets",
      "siege_machines",
      "spells",
      "traps",
      "units",
    ];

    for (final section in sections) {
      if (village.containsKey(section) && village[section] is List) {
        for (final item in village[section]) {
          if (item is Map && item.containsKey("timer")) {
            final String id = item["data"].toString();
            final String? name = buildingMap[id] ?? "unknown_$id";

            upgradingItems.add({
              "id": id,
              "name": name,
              "level": item["lvl"],
              "remaining": item["timer"], // in seconds
              "section": section,
            });
          }
        }
      }
    }

    return upgradingItems;
  }

  // Method to build each timer tile
  Widget _buildTimerTile(TimerModel timer, Duration timeRemaining) {
  // Determine the color based on time remaining
  Color timeColor;
  if (timer.player == "The Wolf") {
    timeColor = Colors.green;
  } else if (timer.player == "Splyce") {
    timeColor = Colors.blue;
  } else if (timer.player == "P.L.U.C.K.") {
    timeColor = Colors.orange;
  } else {
    timeColor = Colors.grey; // Default color for other players
  }

  return InkWell(
    onTap: () async {
      final updatedTimer = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TimerPage(timer: timer),
        ),
      );

      if (updatedTimer != null) {
        await dbHelper.updateTimer(updatedTimer);
        _loadTimers(); // Reload timers after updating
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timer.player, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  timer.upgrade,
                  style: TextStyle(
                    color: timer.upgrade == "Helpers Ready"
                        ? Colors.orange
                        : const Color.fromARGB(255, 173, 173, 173), // Otherwise, grey
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: timeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            height: 40,
            child: Text(
              _formatDuration(timeRemaining),
              style: TextStyle(color: _getBoostedTimeColor(timeRemaining), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

Color _getBoostedTimeColor(Duration adjustedTimeRemaining) {
    final targetTime = DateTime.now().add(adjustedTimeRemaining);

    final hour = targetTime.hour;

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
      bool matchesVillageType = selectedVillageTypes.isEmpty || selectedVillageTypes.contains(timer.village);
      bool matchesPlayer = selectedPlayers.isEmpty || selectedPlayers.contains(timer.player);
      return matchesVillageType && matchesPlayer;
    }).toList();

    filteredTimers.sort((a, b) => a.expiry.compareTo(b.expiry)); // Sort timers by expiry

    setState(() {
      timers = filteredTimers;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _checkExpiredTimers();
      });
    });
  }

  void _checkExpiredTimers() {
    final now = DateTime.now();
    for (var timer in timers) {
      if (timer.expiry.isBefore(now) && !timer.isFinished) {
        timer.isFinished = true;
        dbHelper.updateTimer(timer);
      }
    }
    _loadTimers(); // Reload timers after checking expiry
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
  Future<void> _showPlayerDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Player"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: players.map((player) {
                  return CheckboxListTile(
                    title: Text(player),
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
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _loadTimers(); // Reload timers with applied filters
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without applying filters
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetFilters(BuildContext context) async {
    setState(() {
      selectedVillageTypes.clear();
      selectedPlayers.clear();
    });
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
        title: const Text("Upgrade List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () async {
              setState(() {
                _confirmUploadFromClipboard(context);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () async {
              setState(() {
                displayMode = displayMode == "Timer" ? "Date" : "Timer";
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TimerPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.grey[900], // Match your app's dark background
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                ),
                margin: EdgeInsets.zero, // Removes the default bottom margin
                child: const Text(
                  'Pages',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flash_on, color: Colors.greenAccent),
                title: const Text('Boosts', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BoostPage(timers: timers)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assured_workload, color: Colors.greenAccent),
                title: const Text('Helpers', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpersPage()),
                  );
                },
              ),
              // Add more ListTiles here for future pages
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter buttons above the list
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _resetFilters(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Reset Filters'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _showPlayerDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Player'),
                ),
              ],
            ),
          ),
          // List of timers
          Expanded(
            child: ListView.builder(
              itemCount: timers.length,
              itemBuilder: (context, index) {
                final timer = timers[index];
                final timeRemaining = timer.expiry.difference(DateTime.now());

                return Dismissible(
                  key: Key(timer.id.toString()),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await _confirmDelete(context, timer.id!);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: GestureDetector(
                    onLongPress: () async {
                      return await _updateUpgradeNameOnly(context, timer.id!, timer.upgrade);
                    },
                    child: _buildTimerTile(timer, timeRemaining),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
