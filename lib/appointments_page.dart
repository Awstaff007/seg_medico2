import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico2/auth/auth_service.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/edit_appointment_page.dart'; // Importa la nuova pagina

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late AppDatabase _database;
  late int _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _database = Provider.of<AppDatabase>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = int.parse(authService.currentUserId!);
  }

  Future<void> _deleteAppointment(int appointmentId, String appointmentTitle) async {
    await _database.deleteAppointment(appointmentId);
    await _database.addHistoryEntry(
      MedicalHistoryCompanion(
        userId: Value(_currentUserId),
        eventType: const Value('Appuntamento'),
        details: Value('Appuntamento eliminato: $appointmentTitle'),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _toggleAppointmentStatus(Appointment appointment) async {
    final newStatus = !appointment.isCompleted;
    await _database.updateAppointment(AppointmentsCompanion(
      id: Value(appointment.id),
      isCompleted: Value(newStatus),
    ));

    final details = newStatus
        ? 'Appuntamento completato: ${appointment.doctorName}'
        : 'Stato appuntamento ripristinato: ${appointment.doctorName}';
    
    await _database.addHistoryEntry(
      MedicalHistoryCompanion(
        userId: Value(_currentUserId),
        eventType: const Value('Stato Appuntamento'),
        details: Value(details),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestione Appuntamenti')),
      body: StreamBuilder<List<Appointment>>(
        stream: _database.watchAllAppointmentsForUser(_currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final appointments = snapshot.data!;
          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                child: ListTile(
                  title: Text(
                    appointment.doctorName,
                    style: TextStyle(
                      decoration: appointment.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDate)}'),
                      if (appointment.notes != null && appointment.notes!.isNotEmpty)
                        Text(appointment.notes!),
                    ],
                  ),
                  leading: IconButton(
                    icon: Icon(
                      appointment.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                      color: appointment.isCompleted ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleAppointmentStatus(appointment),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                           Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => EditAppointmentPage(
                              db: _database,
                              userId: _currentUserId,
                              existingAppointment: appointment,
                            ),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAppointment(appointment.id, appointment.doctorName),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // CORREZIONE: Il pulsante ora naviga alla pagina di creazione
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => EditAppointmentPage(
              db: _database,
              userId: _currentUserId,
            ),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
