import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico2/auth/auth_service.dart'; // Per ottenere l'ID utente
import 'package:seg_medico2/data/database.dart'; // Per accedere al database
import 'package:seg_medico2/data/database.g.dart'; // *** NUOVO: Per HistoryEntriesCompanion ***
import 'package:drift/drift.dart' as d; // Importa drift con un prefisso per evitare conflitti

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({super.key});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  late String _currentUserId; // User ID
  late AppDatabase _db; // Database instance

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ottieni l'ID utente dall'AuthService
    _currentUserId = Provider.of<AuthService>(context).currentUserIdNotifier.value!;
    // Ottieni l'istanza del database
    _db = Provider.of<AppDatabase>(context);
  }

  // Funzione di esempio per eliminare un farmaco e registrare l'azione
  Future<void> _deleteMedication(String medicationId, String medicationName) async {
    try {
      // Esegui l'eliminazione dal database. Assicurati che il metodo accetti String.
      await _db.deleteMedication(medicationId); // Questo metodo deve esistere in AppDatabase e accettare String

      // Registra l'azione nella cronologia
      await _db.into(_db.historyEntries).insert(d.HistoryEntriesCompanion.insert( // Usato d.HistoryEntriesCompanion
            userId: _currentUserId,
            eventType: const d.Value('Farmaco'),
            details: d.Value('Farmaco eliminato: $medicationName'),
            timestamp: d.Value(DateTime.now()),
          ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Farmaco "$medicationName" eliminato.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  // Funzione di esempio per aggiornare lo stato di un farmaco e registrare l'azione
  Future<void> _updateMedicationStatus(String medicationId, bool newStatus, String medicationName) async {
    try {
      // Esegui l'aggiornamento nel database. Assicurati che il metodo accetti String.
      await _db.updateMedicationStatus(medicationId, newStatus); // Questo metodo deve esistere in AppDatabase e accettare String

      String details = newStatus ? 'Farmaco attivo: $medicationName' : 'Farmaco inattivo: $medicationName';

      // Registra l'azione nella cronologia
      await _db.into(_db.historyEntries).insert(d.HistoryEntriesCompanion.insert( // Usato d.HistoryEntriesCompanion
            userId: _currentUserId,
            eventType: const d.Value('Stato Farmaco'),
            details: d.Value(details),
            timestamp: d.Value(DateTime.now()),
          ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stato farmaco "$medicationName" aggiornato.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'aggiornamento dello stato: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmaci', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.medical_services, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Questa è la pagina dei Farmaci.',
              style: TextStyle(fontSize: 20, color: Colors.blueGrey),
            ),
            const Text(
              'Qui potrai gestire i farmaci e le prescrizioni.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Esempio di come potresti usare le funzioni (da rimuovere in produzione)
            ElevatedButton(
              onPressed: () {
                _deleteMedication('some_id_med', 'Paracetamolo');
              },
              child: const Text('Simula Eliminazione Farmaco'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateMedicationStatus('another_id_med', false, 'Ibuprofene');
              },
              child: const Text('Simula Inattivazione Farmaco'),
            ),
            Text('Current User ID: $_currentUserId'), // Mostra l'ID utente per debug
          ],
        ),
      ),
    );
  }
}
