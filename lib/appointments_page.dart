import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico2/auth/auth_service.dart'; // Per ottenere l'ID utente
import 'package:seg_medico2/data/database.dart'; // Per accedere al database
// Rimosso: import 'package:seg_medico2/data/database.g.dart'; // NON IMPORTARE I FILE 'part of'
import 'package:drift/drift.dart' as d; // Importa drift con un prefisso per evitare conflitti

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
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

  // Funzione di esempio per eliminare un appuntamento e registrare l'azione
  Future<void> _deleteAppointment(String appointmentId, String appointmentTitle) async {
    try {
      // Esegui l'eliminazione dal database. Assicurati che il metodo accetti String.
      await _db.deleteAppointment(appointmentId); // Questo metodo deve esistere in AppDatabase e accettare String

      // Registra l'azione nella cronologia
      // Usato d.HistoryEntriesCompanion.insert (con prefisso d.)
      await _db.into(_db.historyEntries).insert(d.HistoryEntriesCompanion.insert(
            userId: _currentUserId,
            eventType: const d.Value('Appuntamento'),
            details: d.Value('Appuntamento eliminato: $appointmentTitle'),
            timestamp: d.Value(DateTime.now()),
          ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appuntamento "$appointmentTitle" eliminato.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  // Funzione di esempio per aggiornare lo stato di un appuntamento e registrare l'azione
  Future<void> _updateAppointmentStatus(String appointmentId, bool newStatus, String appointmentTitle) async {
    try {
      // Esegui l'aggiornamento nel database. Assicurati che il metodo accetti String.
      await _db.updateAppointmentStatus(appointmentId, newStatus); // Questo metodo deve esistere in AppDatabase e accettare String

      String details = newStatus ? 'Appuntamento completato: $appointmentTitle' : 'Appuntamento ripristinato: $appointmentTitle';

      // Registra l'azione nella cronologia
      // Usato d.HistoryEntriesCompanion.insert (con prefisso d.)
      await _db.into(_db.historyEntries).insert(d.HistoryEntriesCompanion.insert(
            userId: _currentUserId,
            eventType: const d.Value('Stato Appuntamento'),
            details: d.Value(details),
            timestamp: d.Value(DateTime.now()),
          ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stato appuntamento "$appointmentTitle" aggiornato.')),
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
        title: const Text('Appuntamenti', style: TextStyle(color: Colors.white)),
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
            const Icon(Icons.calendar_today, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Questa è la pagina degli Appuntamenti.',
              style: TextStyle(fontSize: 20, color: Colors.blueGrey),
            ),
            const Text(
              'Qui potrai gestire i tuoi appuntamenti.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Esempio di come potresti usare le funzioni (da rimuovere in produzione)
            ElevatedButton(
              onPressed: () {
                _deleteAppointment('some_id', 'Visita medica');
              },
              child: const Text('Simula Eliminazione Appuntamento'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateAppointmentStatus('another_id', true, 'Controllo annuale');
              },
              child: const Text('Simula Completamento Appuntamento'),
            ),
            Text('Current User ID: $_currentUserId'), // Mostra l'ID utente per debug
          ],
        ),
      ),
    );
  }
}
