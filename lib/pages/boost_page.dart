import 'package:flutter/material.dart';
import 'package:clashofnotifications/models/timer_model.dart';
import 'package:clashofnotifications/models/boost_model.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';

class BoostPage extends StatefulWidget {
  final List<TimerModel> timers;

  const BoostPage({super.key, required this.timers});

  @override
  State<BoostPage> createState() => _BoostPageState();
}

class _BoostPageState extends State<BoostPage> {
  final TextEditingController _boostAmountController = TextEditingController();
  final TextEditingController _boostDurationController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Set<int> _selectedTimerIds = {};

  List<TimerModel> _timers = [];
  List<TimerModel> _filteredTimers = [];

  String? _selectedVillageType;
  String? _selectedPlayer;

  @override
  void initState() {
    super.initState();
    _loadTimers();
    _boostAmountController.addListener(_onBoostValueChanged);
    _boostDurationController.addListener(_onBoostValueChanged);
  }

  Future<void> _loadTimers() async {
    final timers = await _dbHelper.getTimers();
    timers.sort((a, b) => a.expiry.compareTo(b.expiry));
    setState(() {
      _timers = timers;
      _filteredTimers = List.from(_timers); // Initialize with all timers
    });
  }

  void _onBoostValueChanged() {
    setState(() {});
  }

  Color _getBoostedTimeColor(Duration adjustedTimeRemaining) {
    final targetTime = DateTime.now().add(adjustedTimeRemaining); // Calculate the target completion time

    final hour = targetTime.hour;

    // Determine the color based on the target hour
    if (hour >= 23 || hour < 6) {
      return Colors.red; // Between 11 PM and 6 AM
    } else if (hour >= 6 && hour < 7) {
      return Colors.orange; // Between 6 AM and 7 AM
    } else if (hour >= 7 && hour < 8) {
      return Colors.yellow; // Between 7 AM and 8 AM
    } else {
      return Colors.green; // Otherwise (anything else)
    }
  }

  void _submitBoost() async {
    final double? amount = double.tryParse(_boostAmountController.text);
    final int? durationMinutes = int.tryParse(_boostDurationController.text);

    if (amount == null || durationMinutes == null || amount <= 1 || durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid boost amount (>1) and duration")),
      );
      return;
    }

    final selectedTimerIds = _selectedTimerIds.toList();
    if (selectedTimerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one timer to apply the boost.")),
      );
      return;
    }

    final boost = BoostModel(
      amount: amount,
      duration: Duration(minutes: durationMinutes),
      startTime: DateTime.now(),
      affectedTimerIds: selectedTimerIds,
    );

    await _dbHelper.applyBoostAndRescheduleTimers(boost);
    Navigator.pop(context);
  }

  Widget _buildSelectableTimerTile(
    TimerModel timer,
    Duration adjustedTimeRemaining,
    Duration originalTimeRemaining,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timer.player, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    "${timer.village} - ${timer.upgrade}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      Text(
                        "Original: ${_formatDuration(originalTimeRemaining)}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Boosted: ${_formatDuration(adjustedTimeRemaining)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: _getBoostedTimeColor(adjustedTimeRemaining), // Apply dynamic color
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterTimers() {
    setState(() {
      _filteredTimers = _timers.where((timer) {
        final matchesVillageType = _selectedVillageType == null || timer.village == _selectedVillageType;
        final matchesPlayer = _selectedPlayer == null || timer.player == _selectedPlayer;
        return matchesVillageType && matchesPlayer;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply Boost")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              controller: _boostAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Boost Amount",
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _boostDurationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Boost Duration (minutes)",
              ),
            ),
            const SizedBox(height: 20),
            const Text("Select timers to apply boost to:"),
            const SizedBox(height: 10),Row(
              children: [
                // First DropdownButton for Village Type
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedVillageType,
                    hint: const Text(
                      "Village Type",
                      style: TextStyle(color: Colors.white),  // White font color for hint text
                    ),
                    isExpanded: true,  // Ensures it takes up the full width
                    style: const TextStyle(color: Colors.white),  // White font color for the selected value
                    dropdownColor: Colors.black,  // Optional: change dropdown background color
                    items: ["Home Village", "Builder Base"]
                        .map((villageType) => DropdownMenuItem<String>(
                              value: villageType,
                              child: Text(
                                villageType,
                                style: const TextStyle(color: Colors.white),  // White font color for dropdown items
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVillageType = value;
                      });
                      _filterTimers();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Second DropdownButton for Player
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedPlayer,
                    hint: const Text(
                      "Player",
                      style: TextStyle(color: Colors.white),  // White font color for hint text
                    ),
                    isExpanded: true,  // Ensures it takes up the full width
                    style: const TextStyle(color: Colors.white),  // White font color for the selected value
                    dropdownColor: Colors.black,  // Optional: change dropdown background color
                    items: ["The Wolf", "Splyce", "P.L.U.C.K.", "Joe"]
                        .map((player) => DropdownMenuItem<String>(
                              value: player,
                              child: Text(
                                player,
                                style: const TextStyle(color: Colors.white),  // White font color for dropdown items
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPlayer = value;
                      });
                      _filterTimers();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTimers.length,
                itemBuilder: (context, index) {
                  final timer = _filteredTimers[index];
                  final now = DateTime.now();
                  final originalTimeRemaining = timer.expiry.difference(now);

                  final amount = double.tryParse(_boostAmountController.text) ?? 1;
                  final boostDuration = Duration(minutes: int.tryParse(_boostDurationController.text) ?? 0);

                  Duration adjustedTimeRemaining = originalTimeRemaining;

                  if (amount > 1 && boostDuration.inSeconds > 0) {
                    final T = originalTimeRemaining.inSeconds.toDouble();
                    final M = amount;
                    final D = boostDuration.inSeconds.toDouble();
                    final boostCoverage = M * D;

                    double adjustedSeconds;
                    if (T <= boostCoverage) {
                      adjustedSeconds = T / M;
                    } else {
                      adjustedSeconds = D + (T - boostCoverage);
                    }

                    adjustedTimeRemaining = Duration(seconds: adjustedSeconds.floor());
                  }

                  return _buildSelectableTimerTile(
                    timer,
                    adjustedTimeRemaining,
                    originalTimeRemaining,
                    _selectedTimerIds.contains(timer.id ?? -1),
                    () {
                      setState(() {
                        final timerId = timer.id;
                        if (timerId != null) {
                          if (_selectedTimerIds.contains(timerId)) {
                            _selectedTimerIds.remove(timerId);
                          } else {
                            _selectedTimerIds.add(timerId);
                          }
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitBoost,
              child: const Text("Apply Boost"),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) return "Done!";

    int days = duration.inDays;
    int hours = duration.inHours.remainder(24);
    int minutes = duration.inMinutes.remainder(60);

    if (days > 0) return "${days}d ${hours}h ${minutes}m";
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }
}
