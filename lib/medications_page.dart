// lib/medications_page.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart'; // Questo import ora porta tutti i tipi generati
import 'package:seg_medico2/edit_medication_page.dart';
import 'package:drift/drift.dart' hide Column; // Importa Value da drift
import 'package:intl/intl.dart';

class MedicationsPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const MedicationsPage({super.key, required this.db, required this.userId});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  late AppDatabase _database;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _database = widget.db;
    _currentUserId = widget.userId;
  }

  Future<void> _addMedication(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMedicationPage(db: _database, userId: _currentUserId),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farmaco salvato con successo!')),
      );
    }
  }

  Future<void> _editMedication(BuildContext context, Medication medication) async { // Il tipo Medication è ora riconosciuto
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMedicationPage(
          db: _database,
          userId: _currentUserId,
          existingMedication: medication,
        ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farmaco aggiornato con successo!')),
      );
    }
  }

  Future<void> _deleteMedication(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: Text('Sei sicuro di voler eliminare il farmaco "$name"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _database.deleteMedication(id);
      await _database.addHistoryEntry(
        HistoryEntriesCompanion( // Ora riconosciuto
          userId: Value(_currentUserId),
          timestamp: Value(DateTime.now()),
          type: const Value('medication_deleted'),
          description: Value('Farmaco eliminato: $name'),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farmaco eliminato con successo!')),
      );
    }
  }

  Future<void> _toggleMedicationActive(Medication medication) async { // Il tipo Medication è ora riconosciuto
    final newStatus = !medication.isActive;
    await _database.updateMedication(
      MedicationsCompanion( // Corretto da medicationsCompanion a MedicationsCompanion
        id: Value(medication.id),
        isActive: Value(newStatus),
      ),
    );

    String historyDescription = newStatus
        ? 'Farmaco riattivato: ${medication.name}'
        : 'Farmaco disattivato: ${medication.name}';

    await _database.addHistoryEntry(
      HistoryEntriesCompanion( // Ora riconosciuto
        userId: Value(_currentUserId),
        timestamp: Value(DateTime.now()),
        type: Value(newStatus ? 'medication_activated' : 'medication_deactivated'),
        description: Value(historyDescription),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmaci')),
      body: StreamBuilder<List<Medication>>( // Il tipo Medication è ora riconosciuto
        stream: _database.watchAllMedicationsForUser(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessun farmaco. Aggiungine uno!'));
          }
          final medications = snapshot.data!;
          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    medication.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: !medication.isActive ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (medication.dosage != null && medication.dosage!.isNotEmpty)
                        Text('Dosaggio: ${medication.dosage}'),
                      if (medication.frequency != null && medication.frequency!.isNotEmpty)
                        Text('Frequenza: ${medication.frequency}'),
                      if (medication.nextDose != null)
                        Text('Prossima dose: ${DateFormat('dd/MM/yyyy HH:mm').format(medication.nextDose!)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          medication.isActive ? Icons.toggle_on : Icons.toggle_off,
                          color: medication.isActive ? Colors.green : Colors.red,
                        ),
                        onPressed: () => _toggleMedicationActive(medication),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editMedication(context, medication),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMedication(medication.id, medication.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addMedication(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
