import 'package:flutter/material.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';
import 'package:clashofnotifications/pages/time_colour_periods_page.dart';
import 'package:clashofnotifications/pages/players_page.dart';
import 'package:clashofnotifications/pages/village_export_settings_page.dart';

class SettingsPage extends StatelessWidget {
  final DatabaseHelper dbHelper;

  const SettingsPage({super.key, required this.dbHelper});

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
            leading: const Icon(Icons.people, color: Colors.greenAccent),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlayersPage(dbHelper: dbHelper),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              'Village Export Settings',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Configure export preferences for each player',
              style: TextStyle(color: Colors.white70),
            ),
            leading: const Icon(Icons.download, color: Colors.greenAccent),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VillageExportSettingsPage(dbHelper: dbHelper),
                ),
              );
            },
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
            leading: const Icon(Icons.color_lens, color: Colors.greenAccent),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TimeColourPeriodsPage(dbHelper: dbHelper),
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
