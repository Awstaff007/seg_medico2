// lib/appointments_page.dart
import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/main.dart'; // Import main.dart to access getCurrentUserId
import 'package:drift/drift.dart' hide Column; // Import Value from drift, hide Column to avoid conflict

class AppointmentsPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const AppointmentsPage({super.key, required this.db, required this.userId});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late AppDatabase _db;
  late String _currentUserId;
  late Stream<List<Appointment>> _appointmentsStream;
  Profile? _userProfile;

  @override
  void initState() {
    super.initState();
    _db = widget.db;
    _currentUserId = widget.userId;
    _loadProfileAndAppointments();
  }

  Future<void> _loadProfileAndAppointments() async {
    // Watch for profile changes
    _db.watchProfileForUser(_currentUserId).listen((profile) {
      if (profile != null) {
        setState(() {
          _userProfile = profile;
        });
      }
    });
    _appointmentsStream = _db.watchAppointmentsForUser(_currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final double fontSizeScale = _userProfile?.granularFontSizeScale ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('I Miei Appuntamenti'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Nessun appuntamento in programma. Premi "+" per aggiungerne uno.',
                style: TextStyle(fontSize: 18 * fontSizeScale),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final appointments = snapshot.data!;
            // Sort by date and time
            appointments.sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));

            return ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      appointment.title,
                      style: TextStyle(fontSize: 20 * fontSizeScale, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data: ${appointment.appointmentDateTime.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(fontSize: 16 * fontSizeScale),
                        ),
                        Text(
                          'Ora: ${TimeOfDay.fromDateTime(appointment.appointmentDateTime).format(context)}',
                          style: TextStyle(fontSize: 16 * fontSizeScale),
                        ),
                        if (appointment.location != null && appointment.location!.isNotEmpty)
                          Text(
                            'Luogo: ${appointment.location}',
                            style: TextStyle(fontSize: 16 * fontSizeScale),
                          ),
                      ],
                    ),
                    onTap: () {
                      _showAppointmentDialog(context, appointment: appointment);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteAppointment(appointment), // Pass the full object
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAppointmentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAppointmentDialog(BuildContext context, {Appointment? appointment}) async {
    final isEditing = appointment != null;
    final titleController = TextEditingController(text: appointment?.title);
    final locationController = TextEditingController(text: appointment?.location);

    DateTime selectedDate = appointment?.appointmentDateTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(appointment?.appointmentDateTime ?? DateTime.now());

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifica Appuntamento' : 'Nuovo Appuntamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titolo Appuntamento'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Luogo (Opzionale)'),
                ),
                ListTile(
                  title: Text('Data: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (pickedDate != null) {
                      selectedDate = pickedDate;
                      (dialogContext as Element).markNeedsBuild();
                    }
                  },
                ),
                ListTile(
                  title: Text('Ora: ${selectedTime.format(dialogContext)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: dialogContext,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null) {
                      selectedTime = pickedTime;
                      (dialogContext as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Il titolo dell\'appuntamento non può essere vuoto.')),
                  );
                  return;
                }

                if (isEditing) {
                  final updatedAppointment = appointment!.copyWith(
                    title: titleController.text.trim(),
                    location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                    appointmentDateTime: newDateTime,
                  );
                  await _db.updateAppointment(updatedAppointment);
                  await _db.insertHistory( // Corrected: insertHistory
                    HistoriesCompanion(
                      userId: _currentUserId, // No Value()
                      timestamp: DateTime.now(), // No Value()
                      type: 'appointment_updated', // No Value()
                      description: 'Aggiornato appuntamento: ${titleController.text.trim()} il ${newDateTime.toLocal().toString().split(' ')[0]}', // No Value()
                      appointmentId: Value(appointment.id), // Use Value() for nullable foreign key
                    ),
                  );
                } else {
                  final newAppointmentId = await _db.insertAppointment(
                    AppointmentsCompanion(
                      userId: _currentUserId, // No Value()
                      title: titleController.text.trim(), // No Value()
                      location: locationController.text.trim().isEmpty ? null : locationController.text.trim(), // No Value()
                      appointmentDateTime: newDateTime, // No Value()
                    ),
                  );
                  await _db.insertHistory( // Corrected: insertHistory
                    HistoriesCompanion(
                      userId: _currentUserId, // No Value()
                      timestamp: DateTime.now(), // No Value()
                      type: 'appointment_added', // No Value()
                      description: 'Aggiunto appuntamento: ${titleController.text.trim()} il ${newDateTime.toLocal().toString().split(' ')[0]}', // No Value()
                      appointmentId: Value(newAppointmentId), // Use Value() for nullable foreign key
                    ),
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(isEditing ? 'Salva' : 'Aggiungi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAppointment(Appointment appointment) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: Text('Sei sicuro di voler eliminare l\'appuntamento "${appointment.title}"?'),
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

    if (confirm == true) {
      await _db.deleteAppointment(appointment); // Pass the full object
      await _db.deleteAppointmentHistory(appointment.id); // Delete related history entries
      await _db.insertHistory( // Corrected: insertHistory
        HistoriesCompanion(
          userId: _currentUserId, // No Value()
          timestamp: DateTime.now(), // No Value()
          type: 'appointment_deleted', // No Value()
          description: 'Cancellato appuntamento: ${appointment.title}', // No Value()
          appointmentId: Value(appointment.id), // Use Value() for nullable foreign key
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appuntamento "${appointment.title}" eliminato.')),
      );
    }
  }
}