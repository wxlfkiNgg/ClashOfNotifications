import 'package:flutter/material.dart';
import 'package:clashofnotifications/helpers/database_helper.dart'; // Adjust path as needed
import 'package:clashofnotifications/models/timer_model.dart'; // Adjust path as needed

class TimerPage extends StatefulWidget {
  final TimerModel? timer;
  const TimerPage({super.key, this.timer});

  @override
  TimerPageState createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> {
  TextEditingController upgradeController = TextEditingController();
  TextEditingController daysController = TextEditingController();
  TextEditingController hoursController = TextEditingController();
  TextEditingController minutesController = TextEditingController();
  final dbHelper = DatabaseHelper();

  // Create FocusNodes for each TextField
  final FocusNode upgradeFocusNode = FocusNode();
  final FocusNode daysFocusNode = FocusNode();
  final FocusNode hoursFocusNode = FocusNode();
  final FocusNode minutesFocusNode = FocusNode();

  String selectedPlayer = "";
  String selectedVillage = "Home Village";
  String selectedUpgrade = "";
  int selectedDays = 0;
  int selectedHours = 0;
  int selectedMinutes = 0;

  @override
  void initState() {
    super.initState();

    // If editing an existing timer, pre-fill the form
    if (widget.timer != null) {
      selectedPlayer = widget.timer!.player;
      selectedVillage = widget.timer!.village;
      selectedUpgrade = widget.timer!.upgrade;
      upgradeController.text = widget.timer!.upgrade;

      // Convert expiry time to days, hours, and minutes
      final duration = widget.timer!.expiry.difference(DateTime.now());
      
      selectedDays = duration.inDays;
      selectedHours = duration.inHours.remainder(24);
      selectedMinutes = duration.inMinutes.remainder(60);

      // Pre-fill text fields
      daysController.text = selectedDays.toString();
      hoursController.text = selectedHours.toString();
      minutesController.text = selectedMinutes.toString();
    }
  }

  void _clearFields(String fields) {
    setState(() {
      if (fields.contains("upgrade")) {
        upgradeController.clear();
      }
      if (fields.contains("days")) {
        daysController.clear();
      }
      if (fields.contains("hours")) {
        hoursController.clear();
      }
      if (fields.contains("minutes")) {
        minutesController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Timer"),
        actions: [
          TextButton(
            onPressed: () async {
              // 1. Fetch helpers for the selected village
              final helpers = await dbHelper.getHelpersForVillage(selectedPlayer);

              // 2. Show modal with helpers
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF212121),
                    title: const Text('Select Helper', style: TextStyle(color: Color(0xFFF5F5F5))),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: helpers.length,
                        itemBuilder: (context, index) {
                          final helper = helpers[index];
                          return ListTile(
                            title: Text('${helper.player} (${helper.type})', style: const TextStyle(color: Color(0xFFF5F5F5))),
                            subtitle: Text('Amount: ${helper.amount}', style: const TextStyle(color: Color(0xFFBDBDBD))),
                            onTap: () async {
                              // 2. Speed up timer by helper.amount for next 1 hour
                              final now = DateTime.now();
                              final expiry = widget.timer!.expiry;
                              final newExpiry = expiry.subtract(Duration(hours: helper.amount));
                              // Optionally: Store a timestamp to prevent repeated use within 1 hour

                              // Update timer in DB
                              await dbHelper.updateTimer(
                                widget.timer!.copyWith(expiry: newExpiry),
                              );

                              // 3. Check for "Helpers Ready" timer
                              final helpersReadyTimer = await dbHelper.getHelpersReadyTimer(selectedVillage);
                              if (helpersReadyTimer != null && helpersReadyTimer.expiry.isBefore(now)) {
                                // Reset to 23 hours
                                await dbHelper.updateTimer(
                                  helpersReadyTimer.copyWith(expiry: now.add(const Duration(hours: 23))),
                                );
                              }

                              Navigator.of(context).pop(); // Close modal JS
                              
                              // Return to previous screen with new timer
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
            child: const Text(
              "Set Helper Timer",
              style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true, // Ensures the view adjusts when the keyboard appears
      body: SafeArea(  // Wrap the body with SafeArea to prevent overlaps with system buttons
        child: Column(
          children: [
            Expanded(
              // This Expanded widget ensures the content takes up available space
              child: SingleChildScrollView( // Make the body scrollable
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Category Group
                    const Text("Player:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => selectedPlayer = 'The Wolf'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedPlayer == 'The Wolf' ? Colors.green : Colors.grey[300],
                            foregroundColor: selectedPlayer == 'The Wolf' ? Colors.white : Colors.black,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text('The Wolf'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => selectedPlayer = 'Splyce'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedPlayer == 'Splyce' ? Colors.green : Colors.grey[300],
                            foregroundColor: selectedPlayer == 'Splyce' ? Colors.white : Colors.black,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text('Splyce'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => selectedPlayer = 'P.L.U.C.K.'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedPlayer == 'P.L.U.C.K.' ? Colors.green : Colors.grey[300],
                            foregroundColor: selectedPlayer == 'P.L.U.C.K.' ? Colors.white : Colors.black,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text('P.L.U.C.K.'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => selectedPlayer = 'Joe'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedPlayer == 'Joe' ? Colors.green : Colors.grey[300],
                            foregroundColor: selectedPlayer == 'Joe' ? Colors.white : Colors.black,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text('Joe'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Timer Input Section
                    const Text("Set Timer Duration:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Days Input
                        Expanded(
                          child: TextField(
                            controller: daysController,
                            focusNode: daysFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Days"),
                            onSubmitted: (_) {
                              FocusScope.of(context).requestFocus(hoursFocusNode);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Hours Input
                        Expanded(
                          child: TextField(
                            controller: hoursController,
                            focusNode: hoursFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Hours"),
                            onSubmitted: (_) {
                              FocusScope.of(context).requestFocus(minutesFocusNode);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Minutes Input
                        Expanded(
                          child: TextField(
                            controller: minutesController,
                            focusNode: minutesFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Minutes"),
                            onSubmitted: (_) {
                              FocusScope.of(context).requestFocus(upgradeFocusNode);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        SizedBox(
                          width: 40, // Adjust width as needed
                          child: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            tooltip: 'Clear timers',
                            onPressed: () => _clearFields("days,hours,minutes"),
                            padding: EdgeInsets.zero, // Removes extra padding
                            constraints: const BoxConstraints(), // Removes extra constraints
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text("Upgrade:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            textCapitalization: TextCapitalization.words,
                            controller: upgradeController,
                            focusNode: upgradeFocusNode,
                            maxLines: 1,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "",
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            tooltip: 'Clear upgrade',
                            onPressed: () => _clearFields("upgrade"),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Always anchored Submit Button at the bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity, // Makes button span full width of the screen
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Get user inputs
                    final player = selectedPlayer;
                    final village = selectedVillage;
                    final upgrade = upgradeController.text;
                    final days = int.tryParse(daysController.text) ?? 0;
                    final hours = int.tryParse(hoursController.text) ?? 0;
                    final minutes = (int.tryParse(minutesController.text) ?? 0);

                    // Calculate expiry time
                    final duration = Duration(days: days, hours: hours, minutes: minutes);
                    final expiry = DateTime.now().add(duration);

                    // Data validation
                    // Duration
                    if (duration.inSeconds <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid time duration")),
                      );
                      return;
                    }

                    // Other Shit
                    if (selectedPlayer.isEmpty || selectedVillage.isEmpty || upgrade.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill in all fields")),
                      );
                      return;
                    }

                    final newTimer = TimerModel(
                      id: widget.timer?.id, // Keep existing ID if editing
                      player: player,
                      village: village,
                      upgrade: upgrade,
                      expiry: expiry,
                      isFinished: false,
                    );

                    if (widget.timer == null) {
                      // If no existing timer, insert a new one
                      await dbHelper.insertTimer(newTimer);
                    } else {
                      // If editing, update the existing timer
                      await dbHelper.updateTimer(newTimer);
                    }

                    // Return to previous screen with new timer
                    if (context.mounted) {
                      Navigator.pop(context, newTimer);
                    }
                  },
                  child: const Text("Submit"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    daysController.dispose();
    hoursController.dispose();
    minutesController.dispose();
    upgradeController.dispose();
    upgradeFocusNode.dispose();
    daysFocusNode.dispose();
    hoursFocusNode.dispose();
    minutesFocusNode.dispose();
    super.dispose();
  }
}
