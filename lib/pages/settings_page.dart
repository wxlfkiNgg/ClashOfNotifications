import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';
import 'package:clashofnotifications/pages/time_colour_periods_page.dart';
import 'package:clashofnotifications/pages/players_page.dart';

class SettingsPage extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final ValueChanged<Color>? onAccentChanged;

  const SettingsPage({super.key, required this.dbHelper, this.onAccentChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Color dateHeadingColour = Colors.cyanAccent;

  @override
  void initState() {
    super.initState();
    _loadDateHeadingColour();
  }

  Future<void> _loadDateHeadingColour() async {
    final int? colourValue =
        await widget.dbHelper.getAppSettingValue('dateHeadingColour');
    if (colourValue != null) {
      setState(() {
        dateHeadingColour = Color(colourValue);
      });
    }
  }

  Future<void> _showDateHeadingColourDialog() async {
    Color selectedColour = dateHeadingColour;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: Text(
            'Date Heading Colour',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pick a custom colour for the day headings in the timer list.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: selectedColour,
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
                final navigator = Navigator.of(context);
                await widget.dbHelper.saveAppSettingValue(
                    'dateHeadingColour', selectedColour.toARGB32());
                if (!mounted) return;
                setState(() {
                  dateHeadingColour = selectedColour;
                });
                navigator.pop();
              },
              child: Text(
                'Save',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAppAccentColourDialog() async {
    Color selectedColour = Theme.of(context).colorScheme.secondary;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: Text(
            'App Accent Colour',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pick the main app accent colour for the navigation bar, icons, and buttons.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: selectedColour,
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
                final navigator = Navigator.of(context);
                await widget.dbHelper.saveAppSettingValue(
                    'appAccentColour', selectedColour.toARGB32());
                widget.onAccentChanged?.call(selectedColour);
                navigator.pop();
              },
              child: Text(
                'Save',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text(
              'Manage Players',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Add, edit, or remove players and their tags',
              style: TextStyle(color: Colors.white70),
            ),
            leading: Icon(Icons.people, color: Theme.of(context).colorScheme.secondary),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlayersPage(dbHelper: widget.dbHelper),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Display / Personalisation',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize how the timer list headings and visuals appear.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text(
              'App accent colour',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Choose the main accent colour for the app chrome.',
              style: TextStyle(color: Colors.white70),
            ),
            leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.secondary),
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
            ),
            onTap: _showAppAccentColourDialog,
          ),
          ListTile(
            title: const Text(
              'Date heading colour',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Choose the colour for the date headings in the timer list.',
              style: TextStyle(color: Colors.white70),
            ),
            leading: Icon(Icons.format_color_text, color: Theme.of(context).colorScheme.secondary),
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: dateHeadingColour,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
            ),
            onTap: _showDateHeadingColourDialog,
          ),
          ListTile(
            title: const Text(
              'Configure Time Period Colours',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Set custom colours for different time periods',
              style: TextStyle(color: Colors.white70),
            ),
            leading: Icon(Icons.color_lens, color: Theme.of(context).colorScheme.secondary),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TimeColourPeriodsPage(dbHelper: widget.dbHelper),
                ),
              );
            },
          ),
          // Add more settings options here in the future
        ],
      ),
    );
  }
}
