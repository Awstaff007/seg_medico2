// lib/history_page.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart'; // Questo import ora porta tutti i tipi generati
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const HistoryPage({super.key, required this.db, required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late AppDatabase _database;
  late String _currentUserId;
  List<HistoryEntry> _historyEntries = []; // Il tipo HistoryEntry è ora riconosciuto

  @override
  void initState() {
    super.initState();
    _database = widget.db;
    _currentUserId = widget.userId;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _database.getHistoryForUser(_currentUserId);
    setState(() {
      _historyEntries = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronologia Attività'),
      ),
      body: _historyEntries.isEmpty
          ? const Center(child: Text('Nessuna attività registrata.'))
          : ListView.builder(
              itemCount: _historyEntries.length,
              itemBuilder: (context, index) {
                final entry = _historyEntries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  elevation: 2,
                  child: ListTile(
                    title: Text(entry.description),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(entry.timestamp),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    leading: _getIconForHistoryType(entry.type),
                  ),
                );
              },
            ),
    );
  }

  Icon _getIconForHistoryType(String type) {
    switch (type) {
      case 'appointment_completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'appointment_cancelled':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'appointment_deleted':
        return const Icon(Icons.delete_forever, color: Colors.redAccent);
      case 'appointment_added':
        return const Icon(Icons.event_available, color: Colors.blue);
      case 'appointment_updated':
        return const Icon(Icons.edit_calendar, color: Colors.orange);
      case 'appointment_reopened':
        return const Icon(Icons.undo, color: Colors.grey);
      case 'medication_taken':
        return const Icon(Icons.medical_services, color: Colors.purple);
      case 'medication_deleted':
        return const Icon(Icons.delete_forever, color: Colors.redAccent);
      case 'medication_added':
        return const Icon(Icons.add_box, color: Colors.blue);
      case 'medication_updated':
        return const Icon(Icons.edit_note, color: Colors.orange);
      case 'medication_activated':
        return const Icon(Icons.toggle_on, color: Colors.green);
      case 'medication_deactivated':
        return const Icon(Icons.toggle_off, color: Colors.red);
      default:
        return const Icon(Icons.info_outline, color: Colors.grey);
    }
  }
}
