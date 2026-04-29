import 'package:flutter/material.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';
import 'package:clashofnotifications/models/time_colour_period_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TimeColourPeriodsPage extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const TimeColourPeriodsPage({super.key, required this.dbHelper});

  @override
  TimeColourPeriodsPageState createState() => TimeColourPeriodsPageState();
}

class TimeColourPeriodsPageState extends State<TimeColourPeriodsPage> {
  List<TimeColourPeriodModel> periods = [];

  final List<int> _hours = List<int>.generate(24, (index) => index);

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    final loaded = await widget.dbHelper.getTimeColourPeriods();
    setState(() {
      periods = loaded;
    });
  }

  Future<void> _showEditDialog([TimeColourPeriodModel? existing]) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    int selectedStartHour = existing?.startHour ?? 23;
    int selectedEndHour = existing?.endHour ?? 6;
    Color selectedColour = existing?.colour ?? Colors.red;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: Text(
            existing == null ? 'Add Colour Period' : 'Edit Colour Period',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedStartHour,
                  decoration: const InputDecoration(
                    labelText: 'Start hour',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: const Color(0xFF303030),
                  items: _hours
                      .map((hour) => DropdownMenuItem(
                            value: hour,
                            child: Text(
                              '$hour:00',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedStartHour = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedEndHour,
                  decoration: const InputDecoration(
                    labelText: 'End hour',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: const Color(0xFF303030),
                  items: _hours
                      .map((hour) => DropdownMenuItem(
                            value: hour,
                            child: Text(
                              '$hour:00',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedEndHour = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setState) {
                    return ColorPicker(
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
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                if (labelController.text.trim().isEmpty ||
                    selectedStartHour == selectedEndHour) {
                  return;
                }
                final newPeriod = TimeColourPeriodModel(
                  id: existing?.id,
                  label: labelController.text.trim(),
                  startHour: selectedStartHour,
                  endHour: selectedEndHour,
                  colourValue: selectedColour.toARGB32(),
                );

                final navigator = Navigator.of(context);
                final updatedPeriods = [...periods];
                if (existing != null) {
                  final index = updatedPeriods.indexWhere(
                      (period) => period.id == existing.id);
                  if (index >= 0) {
                    updatedPeriods[index] = newPeriod;
                  }
                } else {
                  updatedPeriods.add(newPeriod);
                }

                await widget.dbHelper.saveTimeColourPeriods(updatedPeriods);
                await _loadPeriods();
                navigator.pop();
              },
              child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePeriod(TimeColourPeriodModel period) async {
    if (period.id == null) {
      return;
    }
    await widget.dbHelper.deleteTimeColourPeriod(period.id!);
    await _loadPeriods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Period Colours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add period',
            onPressed: () => _showEditDialog(),
          ),
        ],
      ),
      body: periods.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Custom upgrade colour periods are not configured yet.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Use the + button to add a custom range. The first matching range will determine the timer colour.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: periods.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final period = periods[index];
                final rangeText =
                    '${period.startHour}:00 → ${period.endHour}:00';

                return Card(
                  color: const Color(0xFF212121),
                  child: ListTile(
                    title: Text(period.label,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(rangeText,
                        style: const TextStyle(color: Colors.white70)),
                    leading: CircleAvatar(
                      backgroundColor: period.colour,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deletePeriod(period),
                    ),
                    onTap: () => _showEditDialog(period),
                  ),
                );
              },
            ),
    );
  }
}