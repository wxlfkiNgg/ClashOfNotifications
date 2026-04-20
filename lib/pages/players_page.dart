import 'package:flutter/material.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';
import 'package:clashofnotifications/models/player_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class PlayersPage extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const PlayersPage({super.key, required this.dbHelper});

  @override
  PlayersPageState createState() => PlayersPageState();
}

class PlayersPageState extends State<PlayersPage> {
  List<PlayerModel> players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final loaded = await widget.dbHelper.getPlayers();
    setState(() {
      players = loaded;
    });
  }

  Future<void> _showEditDialog([PlayerModel? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final tagController = TextEditingController(text: existing?.tag ?? '');
    Color selectedColour = existing?.colour ?? Colors.grey;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: Text(
            existing == null ? 'Add Player' : 'Edit Player',
            style: const TextStyle(color: Colors.greenAccent),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Player Name',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Player Tag (e.g., #Q0YY0CR0)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
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
                if (nameController.text.trim().isEmpty ||
                    tagController.text.trim().isEmpty) {
                  return;
                }
                final newPlayer = PlayerModel(
                  id: existing?.id,
                  name: nameController.text.trim(),
                  tag: tagController.text.trim(),
                  colourValue: selectedColour.toARGB32(),
                );

                final updatedPlayers = [...players];
                if (existing != null) {
                  final index = updatedPlayers.indexWhere(
                      (player) => player.id == existing.id);
                  if (index >= 0) {
                    updatedPlayers[index] = newPlayer;
                  }

                  if (existing.name != newPlayer.name) {
                    await widget.dbHelper.updateTimersForPlayerName(
                      existing.name,
                      newPlayer.name,
                    );
                  }
                } else {
                  updatedPlayers.add(newPlayer);
                }

                await widget.dbHelper.savePlayers(updatedPlayers);
                await _loadPlayers();
                Navigator.of(context).pop();
              },
              child: const Text('Save', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  Future<List<PlayerModel>> _defaultPlayers() async {
    return [
      PlayerModel(
          name: 'wolfdakiNgg',
          tag: '#Q0YY0CR0',
          colourValue: Colors.green.toARGB32()),
      PlayerModel(
          name: 'Splyce',
          tag: '#GRJLG0RR0',
          colourValue: Colors.blueAccent.toARGB32()),
      PlayerModel(
          name: 'P.L.U.C.K.',
          tag: '#GQUV2JRY2',
          colourValue: Colors.deepOrangeAccent.toARGB32()),
      PlayerModel(
          name: 'The Big Fella',
          tag: '#L9L80R00',
          colourValue: Colors.green.toARGB32()),
    ];
  }

  Future<void> _resetPlayers() async {
    final defaults = await _defaultPlayers();
    await widget.dbHelper.savePlayers(defaults);
    await _loadPlayers();
  }

  Future<void> _deletePlayer(PlayerModel player) async {
    if (player.id == null) {
      return;
    }
    await widget.dbHelper.updateTimersForPlayerName(
      player.name,
      'Unknown: ${player.tag}',
    );
    await widget.dbHelper.deletePlayer(player.id!);
    await _loadPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Players'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset defaults',
            onPressed: _resetPlayers,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add player',
            onPressed: () => _showEditDialog(),
          ),
        ],
      ),
      body: players.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'No players configured yet.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Use the + button to add players. Player tags are used to identify players from village exports.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: players.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final player = players[index];

                return Card(
                  color: const Color(0xFF212121),
                  child: ListTile(
                    title: Text(player.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(player.tag,
                        style: const TextStyle(color: Colors.white70)),
                    leading: CircleAvatar(
                      backgroundColor: player.colour,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deletePlayer(player),
                    ),
                    onTap: () => _showEditDialog(player),
                  ),
                );
              },
            ),
    );
  }
}