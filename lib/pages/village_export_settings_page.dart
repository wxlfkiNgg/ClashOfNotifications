import 'package:flutter/material.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';
import 'package:clashofnotifications/models/player_model.dart';

class VillageExportSettingsPage extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const VillageExportSettingsPage({super.key, required this.dbHelper});

  @override
  State<VillageExportSettingsPage> createState() =>
      _VillageExportSettingsPageState();
}

class _VillageExportSettingsPageState extends State<VillageExportSettingsPage> {
  late Future<List<PlayerModel>> _playersFuture;

  @override
  void initState() {
    super.initState();
    _playersFuture = widget.dbHelper.getPlayers();
  }

  void _showPlayerExportSettingsDialog(PlayerModel player) {
    showDialog(
      context: context,
      builder: (context) => PlayerExportSettingsDialog(
        player: player,
        dbHelper: widget.dbHelper,
        onSave: () {
          setState(() {
            _playersFuture = widget.dbHelper.getPlayers();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Village Export Settings'),
      ),
      body: FutureBuilder<List<PlayerModel>>(
        future: _playersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final players = snapshot.data ?? [];

          if (players.isEmpty) {
            return const Center(
              child: Text(
                'No players found',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                title: Text(
                  player.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  player.tag,
                  style: const TextStyle(color: Colors.white70),
                ),
                leading: CircleAvatar(
                  backgroundColor: player.colour,
                  child: Text(
                    player.name.isNotEmpty ? player.name[0] : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () => _showPlayerExportSettingsDialog(player),
              );
            },
          );
        },
      ),
    );
  }
}

class PlayerExportSettingsDialog extends StatefulWidget {
  final PlayerModel player;
  final DatabaseHelper dbHelper;
  final VoidCallback onSave;

  const PlayerExportSettingsDialog({
    super.key,
    required this.player,
    required this.dbHelper,
    required this.onSave,
  });

  @override
  State<PlayerExportSettingsDialog> createState() =>
      _PlayerExportSettingsDialogState();
}

class _PlayerExportSettingsDialogState
    extends State<PlayerExportSettingsDialog> {
  late bool exportClockTowerBoost;
  late bool exportHelperTimer;
  late bool exportBuilderBaseUpgrades;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    exportClockTowerBoost = widget.player.exportClockTowerBoost;
    exportHelperTimer = widget.player.exportHelperTimer;
    exportBuilderBaseUpgrades = widget.player.exportBuilderBaseUpgrades;
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    widget.player.exportClockTowerBoost = exportClockTowerBoost;
    widget.player.exportHelperTimer = exportHelperTimer;
    widget.player.exportBuilderBaseUpgrades = exportBuilderBaseUpgrades;

    await widget.dbHelper.updatePlayerExportSettings(widget.player);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      widget.onSave();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        widget.player.name,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text(
                'Export Clock Tower Boost',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Include Clock Tower Boost in exports',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: exportClockTowerBoost,
              onChanged: (value) {
                setState(() {
                  exportClockTowerBoost = value ?? true;
                });
              },
              activeColor: Colors.greenAccent,
              checkColor: Colors.black,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text(
                'Export Helper Timer',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Include Helper Timer in exports',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: exportHelperTimer,
              onChanged: (value) {
                setState(() {
                  exportHelperTimer = value ?? true;
                });
              },
              activeColor: Colors.greenAccent,
              checkColor: Colors.black,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text(
                'Export Builder Base Upgrades',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Include Builder Base Upgrades in exports',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: exportBuilderBaseUpgrades,
              onChanged: (value) {
                setState(() {
                  exportBuilderBaseUpgrades = value ?? true;
                });
              },
              activeColor: Colors.greenAccent,
              checkColor: Colors.black,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(color: Colors.black),
                ),
        ),
      ],
    );
  }
}
