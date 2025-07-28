// lib/appointments_page.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart'; // Questo import ora porta tutti i tipi generati
import 'package:drift/drift.dart' hide Column; // Importa Value da drift
import 'package:intl/intl.dart';

class AppointmentsPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const AppointmentsPage({super.key, required this.db, required this.userId});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late AppDatabase _database;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _database = widget.db;
    _currentUserId = widget.userId;
  }

  Future<void> _addAppointment(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAppointmentPage(db: _database, userId: _currentUserId),
      ),
    );

    if (result == true) {
      // Appuntamento aggiunto/modificato, ricarica la lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appuntamento salvato con successo!')),
      );
    }
  }

  Future<void> _editAppointment(BuildContext context, Appointment appointment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAppointmentPage(
          db: _database,
          userId: _currentUserId,
          existingAppointment: appointment,
        ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appuntamento aggiornato con successo!')),
      );
    }
  }

  Future<void> _deleteAppointment(int id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: Text('Sei sicuro di voler eliminare l\'appuntamento "$title"?'),
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
      await _database.deleteAppointment(id);
      await _database.addHistoryEntry(
        HistoryEntriesCompanion(
          userId: Value(_currentUserId),
          timestamp: Value(DateTime.now()),
          type: const Value('appointment_deleted'),
          description: Value('Appuntamento eliminato: $title'),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appuntamento eliminato con successo!')),
      );
    }
  }

  Future<void> _toggleAppointmentCompletion(Appointment appointment) async {
    final newStatus = !appointment.isCompleted;
    await _database.updateAppointment(
      AppointmentsCompanion( // Ora riconosciuto
        id: Value(appointment.id),
        isCompleted: Value(newStatus),
      ),
    );

    String historyDescription = newStatus
        ? 'Appuntamento completato: ${appointment.title}'
        : 'Stato appuntamento ripristinato: ${appointment.title}';

    await _database.addHistoryEntry(
      HistoryEntriesCompanion( // Ora riconosciuto
        userId: Value(_currentUserId),
        timestamp: Value(DateTime.now()),
        type: Value(newStatus ? 'appointment_completed' : 'appointment_reopened'),
        description: Value(historyDescription),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appuntamenti')),
      body: StreamBuilder<List<Appointment>>( // Il tipo Appointment è ora riconosciuto
        stream: _database.watchAllAppointmentsForUser(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessun appuntamento. Aggiungine uno!'));
          }
          final appointments = snapshot.data!;
          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    appointment.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: appointment.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDate)),
                      if (appointment.description != null && appointment.description!.isNotEmpty)
                        Text(appointment.description!),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          appointment.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                          color: appointment.isCompleted ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _toggleAppointmentCompletion(appointment),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editAppointment(context, appointment),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAppointment(appointment.id, appointment.title),
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
        onPressed: () => _addAppointment(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Devi creare questa pagina (EditAppointmentPage) se non esiste
// Esempio minimo per evitare errori di compilazione immediati
class EditAppointmentPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;
  final Appointment? existingAppointment; // Il tipo Appointment è ora riconosciuto

  const EditAppointmentPage({
    super.key,
    required this.db,
    required this.userId,
    this.existingAppointment,
  });

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingAppointment?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingAppointment?.description ?? '');
    _selectedDate = widget.existingAppointment?.appointmentDate ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(widget.existingAppointment?.appointmentDate ?? DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveAppointment() async {
    if (_formKey.currentState!.validate()) {
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final companion = AppointmentsCompanion( // Ora riconosciuto
        userId: Value(widget.userId),
        title: Value(_titleController.text),
        description: Value(_descriptionController.text.isEmpty ? null : _descriptionController.text),
        appointmentDate: Value(combinedDateTime),
        isCompleted: Value(widget.existingAppointment?.isCompleted ?? false),
      );

      if (widget.existingAppointment == null) {
        await widget.db.addAppointment(companion);
        await widget.db.addHistoryEntry(
          HistoryEntriesCompanion( // Ora riconosciuto
            userId: Value(widget.userId),
            timestamp: Value(DateTime.now()),
            type: const Value('appointment_added'),
            description: Value('Nuovo appuntamento aggiunto: ${_titleController.text}'),
          ),
        );
      } else {
        await widget.db.updateAppointment(companion.copyWith(id: Value(widget.existingAppointment!.id)));
        await widget.db.addHistoryEntry(
          HistoryEntriesCompanion( // Ora riconosciuto
            userId: Value(widget.userId),
            timestamp: Value(DateTime.now()),
            type: const Value('appointment_updated'),
            description: Value('Appuntamento aggiornato: ${_titleController.text}'),
          ),
        );
      }
      Navigator.pop(context, true); // Ritorna true per indicare il successo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingAppointment == null ? 'Nuovo Appuntamento' : 'Modifica Appuntamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titolo Appuntamento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrizione (Opzionale)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text('Ora: ${_selectedTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAppointment,
                child: Text(widget.existingAppointment == null ? 'Aggiungi Appuntamento' : 'Salva Modifiche'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
