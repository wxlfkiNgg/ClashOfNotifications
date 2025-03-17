import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:clashofnotifications/pages/add_timer_page.dart';
import 'package:clashofnotifications/models/timer_model.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await notificationsPlugin.initialize(initializationSettings);
  
  // Initialize timezone support
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Australia/Brisbane')); // Change this to your actual timezone
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[900], // Set background to grey
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
          labelStyle: const TextStyle(color: Colors.white), // Label text color
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
  List<TimerModel> timers = [];
  late DatabaseHelper dbHelper;
  Timer? _timer;
  FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> _requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

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
                _loadTimers();
                Navigator.of(context).pop(true);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Widget _buildTimerTile(TimerModel timer, Duration timeRemaining) {
    return InkWell(
      onTap: () async {
        final updatedTimer = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTimerPage(timer: timer),
          ),
        );

        if (updatedTimer != null) {
          await dbHelper.updateTimer(updatedTimer);
          _loadTimers(); // Refresh UI after editing
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
                  Text("${timer.village} - ${timer.upgrade}", style: TextStyle(color: const Color.fromARGB(255, 173, 173, 173))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green,
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
    _loadTimers();
    _startTimer();
  }

  Future<void> _loadTimers() async {
    final loadedTimers = await dbHelper.getTimers();
    loadedTimers.sort((a, b) => a.expiry.compareTo(b.expiry));
    
    setState(() {
      timers = loadedTimers;
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
    _loadTimers();
  }

  String _formatDuration(Duration duration) {
    int days = duration.inDays;
    int hours = duration.inHours.remainder(24);
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    if (duration.isNegative || duration == Duration.zero) {
      return "Done!";
    } else if (days == 0) {
      if (hours == 0) {
        return "${minutes}m ${seconds}s";
      } else {
        return "${hours}h ${minutes}m";
      }
    } else {
      return "${days}d ${hours}h ${minutes}m";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upgrade List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTimerPage()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: timers.length,
        itemBuilder: (context, index) {
          final timer = timers[index];
          final timeRemaining = timer.expiry.difference(DateTime.now());

          return Dismissible(
            key: Key(timer.id.toString()), // Unique key for each item
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
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}