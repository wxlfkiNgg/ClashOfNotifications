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
    final dialogContext = context;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final tagController = TextEditingController(text: existing?.tag ?? '');
    Color selectedColour = existing?.colour ?? Colors.grey;
    bool active = existing?.active ?? true;

    await showDialog(
      context: dialogContext,
      builder: (context) {
        final dialogContext = context;
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: Text(
            existing == null ? 'Add Player' : 'Edit Player',
            style: const TextStyle(color: Colors.greenAccent),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
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
                    SwitchListTile(
                      title: const Text('Active', style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                        'If inactive, this village will be hidden and no timers will load',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: active,
                      onChanged: (value) {
                        setState(() {
                          active = value;
                        });
                      },
                      activeThumbColor: Colors.greenAccent,
                    ),
                    const SizedBox(height: 8),
                    ColorPicker(
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
                    ),
                  ],
                ),
              );
            },
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
                  active: active,
                  displayOrder: existing?.displayOrder ?? players.length,
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

                navigator.pop();
                await widget.dbHelper.savePlayers(updatedPlayers);
                await _loadPlayers();
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
          colourValue: Colors.green.toARGB32(),
          active: true,
          displayOrder: 0),
      PlayerModel(
          name: 'Splyce',
          tag: '#GRJLG0RR0',
          colourValue: Colors.blueAccent.toARGB32(),
          active: true,
          displayOrder: 1),
      PlayerModel(
          name: 'P.L.U.C.K.',
          tag: '#GQUV2JRY2',
          colourValue: Colors.deepOrangeAccent.toARGB32(),
          active: true,
          displayOrder: 2),
      PlayerModel(
          name: 'The Big Fella',
          tag: '#L9L80R00',
          colourValue: Colors.green.toARGB32(),
          active: true,
          displayOrder: 3),
    ];
  }

  Future<void> _resetPlayers() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF212121),
              title: const Text('Reset default players?',
                  style: TextStyle(color: Colors.greenAccent)),
              content: const Text(
                'This will restore the default player list and overwrite any custom players you have added.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.redAccent)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Reset',
                      style: TextStyle(color: Colors.greenAccent)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final defaults = await _defaultPlayers();
    await widget.dbHelper.savePlayers(defaults);
    await _loadPlayers();
  }

  Future<void> _deletePlayer(PlayerModel player) async {
    if (player.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF212121),
              title: const Text('Delete player?',
                  style: TextStyle(color: Colors.greenAccent)),
              content: Text(
                'Are you sure you want to delete ${player.name}? This will keep existing timers but move them to Unknown: ${player.tag}.',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.redAccent)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.greenAccent)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await widget.dbHelper.updateTimersForPlayerName(
      player.name,
      'Unknown: ${player.tag}',
    );
    await widget.dbHelper.deletePlayer(player.id!);
    await _loadPlayers();
  }

  Future<void> _onReorderPlayers(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final updatedPlayers = [...players];
    final movedPlayer = updatedPlayers.removeAt(oldIndex);
    updatedPlayers.insert(newIndex, movedPlayer);

    for (var i = 0; i < updatedPlayers.length; i++) {
      updatedPlayers[i].displayOrder = i;
    }

    await widget.dbHelper.savePlayers(updatedPlayers);
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
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: players.length,
              onReorder: _onReorderPlayers,
              itemBuilder: (context, index) {
                final player = players[index];

                return Card(
                  key: ValueKey(player.id ?? player.tag),
                  color: const Color(0xFF212121),
                  child: ListTile(
                    title: Text(player.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(player.tag,
                        style: const TextStyle(color: Colors.white70)),
                    leading: CircleAvatar(
                      backgroundColor: player.colour,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.drag_handle, color: Colors.white70),
                          ),
                        ),
                        Switch(
                          value: player.active,
                          activeThumbColor: Colors.greenAccent,
                          onChanged: (value) async {
                            player.active = value;
                            await widget.dbHelper.savePlayers(players);
                            await _loadPlayers();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deletePlayer(player),
                        ),
                      ],
                    ),
                    onTap: () => _showEditDialog(player),
                  ),
                );
              },
            ),
    );
  }
}