import 'package:clashofnotifications/models/boost_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:clashofnotifications/pages/timer_page.dart';
import 'package:clashofnotifications/models/timer_model.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';
import 'package:clashofnotifications/pages/boost_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

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
  final List<String> players = ['The Wolf', 'Splyce', 'P.L.U.C.K.', 'Joe'];

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

  // Method to confirm the deletion of a timer
  Future<bool> _confirmDelete(BuildContext context, int timerId) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Delete Timer?"),
              content: const Text("Are you sure you want to delete this timer?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
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
  } else if (timer.player == "Joe") {
    timeColor = Colors.red;
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
                Text("${timer.village} - ${timer.upgrade}", style: TextStyle(color: Color.fromARGB(255, 173, 173, 173))),
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
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
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

  // Show Village Type filter dialog
  Future<void> _showVillageTypeDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Village Type"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: villageTypes.map((villageType) {
                  return CheckboxListTile(
                    title: Text(villageType),
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
            icon: const Icon(Icons.timer),
            onPressed: () async {
              if (displayMode == "Timer") {
                setState(() {
                  displayMode = "Date";
                });
              } else {
                setState(() {
                  displayMode = "Timer";
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BoostPage(timers: timers)),
              );
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
                    await _showPlayerDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Player'),
                ),
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
                    await _showVillageTypeDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Village Type'),
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
                  child: _buildTimerTile(timer, timeRemaining),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
