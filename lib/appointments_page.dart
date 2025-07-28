// lib/appointments_page.dart

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column; // Importa Value da drift
import 'package:seg_medico2/data/database.dart'; // Importa il tuo database

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final AppDatabase _database = AppDatabase();
  String? _currentUserId; // L'ID dell'utente corrente

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ottieni l'ID dell'utente corrente. Simile a MedicationsPage.
    _currentUserId = 'test_user_id'; // Sostituisci con la logica reale del tuo utente
  }

  // Funzione per mostrare il dialogo di aggiunta/modifica appuntamento
  void _showAddEditAppointmentDialog({Appointment? existingAppointment}) async {
    if (_currentUserId == null) {
      _showMessage('Errore: ID utente non disponibile.');
      return;
    }

    final isEditing = existingAppointment != null;
    final titleController = TextEditingController(text: existingAppointment?.title ?? '');
    final locationController = TextEditingController(text: existingAppointment?.location ?? '');
    DateTime selectedDateTime = existingAppointment?.appointmentDateTime ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifica Appuntamento' : 'Aggiungi Appuntamento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titolo appuntamento'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Luogo (opzionale)'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Data: ${selectedDateTime.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        selectedDateTime.hour,
                        selectedDateTime.minute,
                      );
                    });
                  }
                },
              ),
              ListTile(
                title: Text('Ora: ${selectedDateTime.toLocal().hour.toString().padLeft(2, '0')}:${selectedDateTime.toLocal().minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      selectedDateTime = DateTime(
                        selectedDateTime.year,
                        selectedDateTime.month,
                        selectedDateTime.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                _showMessage('Il titolo dell\'appuntamento non può essere vuoto.');
                return;
              }

              final newDateTime = selectedDateTime; // Usa il DateTime aggiornato

              if (isEditing) {
                // Aggiorna appuntamento esistente
                await _database.updateAppointment(
                  AppointmentsCompanion(
                    id: Value(existingAppointment!.id), // ID dell'appuntamento da aggiornare
                    userId: Value(_currentUserId!), // Incapsula la stringa con Value()
                    title: Value(titleController.text.trim()), // Incapsula la stringa con Value()
                    location: Value(locationController.text.trim().isEmpty ? null : locationController.text.trim()), // Incapsula String? con Value()
                    appointmentDateTime: Value(newDateTime), // Incapsula DateTime con Value()
                  ),
                );
                // Registra l'azione nella cronologia
                await _database.addHistoryEntry(
                  HistoryEntriesCompanion(
                    userId: Value(_currentUserId!), // Incapsula la stringa con Value()
                    timestamp: Value(DateTime.now()), // Incapsula DateTime con Value()
                    type: Value('appointment_updated'), // Incapsula la stringa con Value()
                    description: Value('Aggiornato appuntamento: ${titleController.text.trim()} il ${newDateTime.toLocal().toString().split(' ')[0]}'), // Incapsula la stringa con Value()
                  ),
                );
                _showMessage('Appuntamento aggiornato con successo!');
              } else {
                // Aggiungi nuovo appuntamento
                await _database.addAppointment(
                  AppointmentsCompanion(
                    userId: Value(_currentUserId!), // Incapsula la stringa con Value()
                    title: Value(titleController.text.trim()), // Incapsula la stringa con Value()
                    location: Value(locationController.text.trim().isEmpty ? null : locationController.text.trim()), // Incapsula String? con Value()
                    appointmentDateTime: Value(newDateTime), // Incapsula DateTime con Value()
                  ),
                );
                // Registra l'azione nella cronologia
                await _database.addHistoryEntry(
                  HistoryEntriesCompanion(
                    userId: Value(_currentUserId!), // Incapsula la stringa con Value()
                    timestamp: Value(DateTime.now()), // Incapsula DateTime con Value()
                    type: Value('appointment_added'), // Incapsula la stringa con Value()
                    description: Value('Aggiunto appuntamento: ${titleController.text.trim()} il ${newDateTime.toLocal().toString().split(' ')[0]}'), // Incapsula la stringa con Value()
                  ),
                );
                _showMessage('Appuntamento aggiunto con successo!');
              }
              Navigator.of(context).pop(); // Chiudi il dialogo
            },
            child: Text(isEditing ? 'Salva' : 'Aggiungi'),
          ),
        ],
      ),
    );
  }

  // Funzione per eliminare un appuntamento
  void _deleteAppointment(Appointment appointment) async {
    if (_currentUserId == null) {
      _showMessage('Errore: ID utente non disponibile.');
      return;
    }

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Sei sicuro di voler eliminare l\'appuntamento "${appointment.title}"?'),
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
      // Elimina l'appuntamento dal database
      await _database.deleteAppointment(appointment.id);

      // Registra l'azione nella cronologia
      await _database.addHistoryEntry(
        HistoryEntriesCompanion(
          userId: Value(_currentUserId!), // Incapsula la stringa con Value()
          timestamp: Value(DateTime.now()), // Incapsula DateTime con Value()
          type: Value('appointment_deleted'), // Incapsula la stringa con Value()
          description: Value('Cancellato appuntamento: ${appointment.title}'), // Incapsula la stringa con Value()
        ),
      );
      _showMessage('Appuntamento eliminato con successo!');
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
        appBar: AppBar(title: Text('Appuntamenti')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appuntamenti'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: StreamBuilder<List<Appointment>>(
        // Ascolta i cambiamenti sugli appuntamenti per l'utente corrente
        stream: _database.watchAllAppointmentsForUser(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessun appuntamento aggiunto.'));
          } else {
            final appointments = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
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
                          appointment.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Data e Ora: ${appointment.appointmentDateTime.toLocal().toString().split('.')[0]}'),
                        Text('Luogo: ${appointment.location ?? 'Nessuno'}'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditAppointmentDialog(existingAppointment: appointment),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAppointment(appointment),
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
        onPressed: () => _showAddEditAppointmentDialog(),
        tooltip: 'Aggiungi Appuntamento',
        child: const Icon(Icons.add),
      ),
    );
  }
}
