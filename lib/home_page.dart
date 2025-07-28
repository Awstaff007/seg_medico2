import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seg_medico2/data/database.dart';
// CORREZIONE: Aggiunto import mancante per usare 'Value'
import 'package:drift/drift.dart';

class HomePage extends StatefulWidget {
  final AppDatabase db;
  final int userId;

  const HomePage({Key? key, required this.db, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Appointment? _nextAppointment;
  Medication? _nextMedication;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final allAppointments = await widget.db.getAllAppointmentsForUser(widget.userId);
    final allMedications = await widget.db.getAllMedicationsForUser(widget.userId);

    setState(() {
      _nextAppointment = allAppointments.isNotEmpty ? allAppointments.first : null;
      _nextMedication = allMedications.isNotEmpty ? allMedications.first : null;
    });
  }

  Future<void> _completeAppointment() async {
    if (_nextAppointment != null) {
      // CORREZIONE: 'Value' ora è riconosciuto
      await widget.db.updateAppointment(AppointmentsCompanion(
        id: Value(_nextAppointment!.id),
        isCompleted: const Value(true),
      ));
      await widget.db.addHistoryEntry(
        MedicalHistoryCompanion(
          userId: Value(widget.userId),
          eventType: const Value('Appuntamento'),
          details: Value('Appuntamento completato: ${_nextAppointment!.doctorName}'),
          timestamp: Value(DateTime.now()),
        ),
      );
      _loadInitialData();
    }
  }

  Future<void> _takeMedication() async {
    if (_nextMedication != null) {
      await widget.db.updateMedication(MedicationsCompanion(
        id: Value(_nextMedication!.id),
        nextDose: Value(_nextMedication!.nextDose?.add(const Duration(days: 1))),
      ));
      await widget.db.addHistoryEntry(
        MedicalHistoryCompanion(
          userId: Value(widget.userId),
          eventType: const Value('Farmaco'),
          details: Value('Farmaco assunto: ${_nextMedication!.name}'),
          timestamp: Value(DateTime.now()),
        ),
      );
      _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Principale')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prossimo Appuntamento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_nextAppointment != null)
              Card(
                child: ListTile(
                  title: Text(_nextAppointment!.doctorName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(_nextAppointment!.appointmentDate)}'),
                      if (_nextAppointment!.notes != null && _nextAppointment!.notes!.isNotEmpty)
                        Text('Note: ${_nextAppointment!.notes}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: _completeAppointment,
                    child: const Text('Completato'),
                  ),
                ),
              )
            else
              const Text('Nessun appuntamento imminente.'),
            const SizedBox(height: 20),
            const Text('Prossimo Farmaco da Assumere', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_nextMedication != null)
              Card(
                child: ListTile(
                  title: Text(_nextMedication!.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dosaggio: ${_nextMedication!.dosage}'),
                      Text('Frequenza: ${_nextMedication!.frequency}'),
                      if (_nextMedication!.nextDose != null)
                         Text('Prossima dose: ${DateFormat('dd/MM/yyyy HH:mm').format(_nextMedication!.nextDose!)}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: _takeMedication,
                    child: const Text('Assunto'),
                  ),
                ),
              )
            else
              const Text('Nessun farmaco da assumere.'),
          ],
        ),
      ),
    );
  }
}
