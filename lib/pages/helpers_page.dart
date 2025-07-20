import 'package:flutter/material.dart';
import '../models/helper_model.dart';
import 'package:clashofnotifications/helpers/database_helper.dart';

class HelpersPage extends StatefulWidget {
  const HelpersPage({Key? key}) : super(key: key);

  @override
  _HelpersPageState createState() => _HelpersPageState();
}

class _HelpersPageState extends State<HelpersPage> {
  late DatabaseHelper dbHelper;
  List<HelperModel> helpers = [];
  final List<String> players = ["The Wolf", "Splyce", "Other"]; // Example player list

  Future<void> _loadHelpers() async {
    // Replace with your actual database logic
    helpers = await dbHelper.getHelpers();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _loadHelpers();
  }

  Future<void> _showHelperDialog({HelperModel? helper}) async {
    final isEditing = helper != null;
    String selectedPlayer = helper?.player ?? players.first;
    TextEditingController typeController = TextEditingController(text: helper?.type ?? '');
    TextEditingController amountController = TextEditingController(text: helper?.amount?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121), // Dark grey
          title: Text(
            isEditing ? 'Edit Helper' : 'Add Helper',
            style: const TextStyle(color: Color(0xFFF5F5F5)), // Light white
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPlayer,
                items: players
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p,
                            style: const TextStyle(color: Color(0xFFF5F5F5)), // White
                          ),
                        ))
                    .toList(),
                onChanged: (val) => selectedPlayer = val ?? players.first,
                decoration: const InputDecoration(
                  labelText: 'Player',
                  labelStyle: TextStyle(color: Color(0xFFBDBDBD)), // Medium grey
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                ),
                dropdownColor: const Color(0xFF212121), // Dark grey dropdown
                style: const TextStyle(color: Color(0xFFF5F5F5)), // White selected text
              ),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(color: Color(0xFFBDBDBD)), // Medium grey
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                ),
                style: const TextStyle(color: Color(0xFFBDBDBD)), // Medium grey
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Color(0xFFBDBDBD)), // Medium grey
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFFBDBDBD)), // Medium grey
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFBDBDBD))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF424242), // Slightly lighter dark
                foregroundColor: const Color(0xFFF5F5F5), // Light white text
              ),
              onPressed: () async {
                final type = typeController.text.trim();
                final amount = int.tryParse(amountController.text.trim()) ?? 0;
                if (type.isEmpty || amount <= 0) return;
                if (isEditing) {
                  await dbHelper.updateHelper(
                    HelperModel(
                      id: helper.id,
                      player: selectedPlayer,
                      type: type,
                      amount: amount,
                    ),
                  );
                } else {
                  await dbHelper.insertHelper(
                    HelperModel(
                      player: selectedPlayer,
                      type: type,
                      amount: amount,
                    ),
                  );
                }
                Navigator.of(context).pop();
                await _loadHelpers();
              },
              child: const Text('Submit'),
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
        title: const Text('Helpers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showHelperDialog(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: helpers.length,
        itemBuilder: (context, index) {
          final helper = helpers[index];
          return Dismissible(
            key: Key(helper.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) async {
              await dbHelper.deleteHelper(helper.id);
              helpers.removeAt(index);
              setState(() {});
            },
            child: ListTile(
              title: Text(
                '${helper.type} - ${helper.player}',
                style: const TextStyle(
                  color: Color(0xFFF5F5F5), // Light white
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Amount: ${helper.amount}',
                style: const TextStyle(
                  color: Color(0xFFBDBDBD), // Light grey
                ),
              ),
              onTap: () => _showHelperDialog(helper: helper),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showHelperDialog(helper: helper),
              ),
            ),
          );
        },
      ),
    );
  }
}