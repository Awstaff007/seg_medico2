// lib/medications_page.dart

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column; // Importa Value da drift
import 'package:seg_medico2/data/database.dart'; // Importa il tuo database
import 'package:seg_medico2/edit_medication_page.dart'; // Percorso corretto per EditMedicationPage

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({super.key});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  // Istanza del database. Assicurati che sia inizializzata correttamente.
  // Potrebbe essere passata tramite Provider o un'altra forma di gestione dello stato.
  final AppDatabase _database = AppDatabase();
  String? _currentUserId; // L'ID dell'utente corrente

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ottieni l'ID dell'utente corrente. Questo è un placeholder.
    // In un'app reale, useresti Firebase Auth o un sistema di autenticazione simile
    // per ottenere l'ID dell'utente loggato.
    // Per ora, useremo un ID statico o un ID da un wrapper di autenticazione.
    // Se usi AuthWrapper, potresti recuperarlo così:
    // final authWrapper = AuthWrapper.of(context);
    // _currentUserId = authWrapper?.userId;
    // Per questo esempio, assumiamo che sia disponibile o un valore di test.
    _currentUserId = 'test_user_id'; // Sostituisci con la logica reale del tuo utente
  }

  // Funzione per aggiungere un nuovo farmaco
  void _addMedication() async {
    if (_currentUserId == null) {
      _showMessage('Errore: ID utente non disponibile.');
      return;
    }

    final newMedication = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(
        builder: (context) => const EditMedicationPage(),
      ),
    );

    if (newMedication != null) {
      // Inserisci il nuovo farmaco nel database
      await _database.addMedication(
        MedicationsCompanion(
          userId: Value(_currentUserId!), // Incapsula la stringa con Value()
          name: Value(newMedication.name), // Incapsula la stringa con Value()
          dosage: Value(newMedication.dosage), // Incapsula la stringa con Value()
          frequency: Value(newMedication.frequency), // Incapsula la stringa con Value()
          notes: Value(newMedication.notes), // Incapsula la stringa con Value()
          startDate: Value(newMedication.startDate), // Incapsula DateTime con Value()
          endDate: Value(newMedication.endDate), // Incapsula DateTime con Value()
        ),
      );

      // Registra l'azione nella cronologia
      await _database.addHistoryEntry(
        HistoryEntriesCompanion(
          userId: Value(_currentUserId!), // Incapsula la stringa con Value()
          timestamp: Value(DateTime.now()), // Incapsula DateTime con Value()
          type: Value('medication_added'), // Incapsula la stringa con Value()
          description: Value('Aggiunto farmaco: ${newMedication.name}'), // Incapsula la stringa con Value()
        ),
      );
      _showMessage('Farmaco aggiunto con successo!');
    }
  }

  // Funzione per modificare un farmaco esistente
  void _editMedication(Medication medication) async {
    if (_currentUserId == null) {
      _showMessage('Errore: ID utente non disponibile.');
      return;
    }

    final updatedMedication = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(
        builder: (context) => EditMedicationPage(existingMedication: medication),
      ),
    );

    if (updatedMedication != null) {
      // Aggiorna il farmaco nel database
      await _database.updateMedication(
        MedicationsCompanion(
          id: Value(medication.id), // L'ID del farmaco da aggiornare
          userId: Value(_currentUserId!), // Incapsula la stringa con Value()
          name: Value(updatedMedication.name), // Incapsula la stringa con Value()
          dosage: Value(updatedMedication.dosage), // Incapsula la stringa con Value()
          frequency: Value(updatedMedication.frequency), // Incapsula la stringa con Value()
          notes: Value(updatedMedication.notes), // Incapsula la stringa con Value()
          startDate: Value(updatedMedication.startDate), // Incapsula DateTime con Value()
          endDate: Value(updatedMedication.endDate), // Incapsula DateTime con Value()
        ),
      );

      // Registra l'azione nella cronologia
      await _database.addHistoryEntry(
        HistoryEntriesCompanion(
          userId: Value(_currentUserId!), // Incapsula la stringa con Value()
          timestamp: Value(DateTime.now()), // Incapsula DateTime con Value()
          type: Value('medication_updated'), // Incapsula la stringa con Value()
          description: Value('Aggiornato farmaco: ${updatedMedication.name}'), // Incapsula la stringa con Value()
        ),
      );
      _showMessage('Farmaco aggiornato con successo!');
    }
  }

  // Funzione per eliminare un farmaco
  void _deleteMedication(Medication medication) async {
    if (_currentUserId == null) {
      _showMessage('Errore: ID utente non disponibile.');
      return;
    }

    // Mostra un dialogo di conferma
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Sei sicuro di voler eliminare il farmaco "${medication.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      // Elimina il farmaco dal database
      await _database.deleteMedication(medication.id);

      // Registra l'azione nella cronologia
      await _database.addHistoryEntry(
        HistoryEntriesCompanion(
          userId: Value(_currentUserId!), // Incapsula la stringa con Value()
          timestamp: Value(DateTime.now()), // Incapsula DateTime con Value()
          type: Value('medication_deleted'), // Incapsula la stringa con Value()
          description: Value('Cancellato farmaco: ${medication.name}'), // Incapsula la stringa con Value()
        ),
      );
      _showMessage('Farmaco eliminato con successo!');
    }
  }

  // Funzione per mostrare un messaggio all'utente
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        appBar: AppBar(title: Text('Farmaci')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmaci'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: StreamBuilder<List<Medication>>(
        // Ascolta i cambiamenti sui farmaci per l'utente corrente
        stream: _database.watchAllMedicationsForUser(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessun farmaco aggiunto.'));
          } else {
            final medications = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final medication = medications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Dosaggio: ${medication.dosage}'),
                        Text('Frequenza: ${medication.frequency}'),
                        Text('Note: ${medication.notes.isNotEmpty ? medication.notes : 'Nessuna'}'),
                        Text('Inizio: ${medication.startDate.toLocal().toString().split(' ')[0]}'),
                        Text('Fine: ${medication.endDate.toLocal().toString().split(' ')[0]}'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editMedication(medication),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteMedication(medication),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        tooltip: 'Aggiungi Farmaco',
        child: const Icon(Icons.add),
      ),
    );
  }
}
