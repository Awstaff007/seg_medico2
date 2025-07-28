// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart'; // Questo import ora porta tutti i tipi generati (Appointment, Medication, HistoryEntry, Companion classes)
import 'package:seg_medico2/appointments_page.dart';
import 'package:seg_medico2/medications_page.dart';
import 'package:seg_medico2/history_page.dart';
import 'package:drift/drift.dart' hide Column; // Importa Value da drift, nascondendo Column per evitare conflitti
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart'; // Per la formattazione della data

class HomePage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const HomePage({super.key, required this.db, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // I tipi ora dovrebbero essere riconosciuti correttamente grazie all'import di database.dart
  Appointment? _nextAppointment;
  Medication? _nextMedication;

  @override
  void initState() {
    super.initState();
    _loadNextAppointment();
    _loadNextMedication();
  }

  Future<void> _loadNextAppointment() async {
    // allAppointments è ora List<Appointment>, quindi i getter sono disponibili
    final allAppointments = await widget.db.getAllAppointmentsForUser(widget.userId);
    final upcomingAppointments = allAppointments.where((a) => !a.isCompleted && a.appointmentDate.isAfter(DateTime.now())).toList();
    upcomingAppointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    setState(() {
      _nextAppointment = upcomingAppointments.isNotEmpty ? upcomingAppointments.first : null;
    });
  }

  Future<void> _loadNextMedication() async {
    // allMedications è ora List<Medication>, quindi i getter sono disponibili
    final allMedications = await widget.db.getAllMedicationsForUser(widget.userId);
    final upcomingMedications = allMedications.where((m) => m.isActive && m.nextDose != null && m.nextDose!.isAfter(DateTime.now())).toList();
    upcomingMedications.sort((a, b) => a.nextDose!.compareTo(b.nextDose!));
    setState(() {
      _nextMedication = upcomingMedications.isNotEmpty ? upcomingMedications.first : null;
    });
  }

  Future<void> _completeAppointment() async {
    if (_nextAppointment != null) {
      await widget.db.updateAppointment(
        AppointmentsCompanion(
          id: Value(_nextAppointment!.id),
          isCompleted: const Value(true),
        ),
      );
      await widget.db.addHistoryEntry(
        HistoryEntriesCompanion(
          userId: Value(widget.userId),
          timestamp: Value(DateTime.now()),
          type: const Value('appointment_completed'),
          description: Value('Appuntamento completato: ${_nextAppointment!.title}'),
        ),
      );
      _loadNextAppointment(); // Ricarica il prossimo appuntamento
    }
  }

  Future<void> _cancelAppointment() async {
    if (_nextAppointment != null) {
      await widget.db.deleteAppointment(_nextAppointment!.id);
      await widget.db.addHistoryEntry(
        HistoryEntriesCompanion(
          userId: Value(widget.userId),
          timestamp: Value(DateTime.now()),
          type: const Value('appointment_cancelled'),
          description: Value('Appuntamento annullato: ${_nextAppointment!.title}'),
        ),
      );
      _loadNextAppointment(); // Ricarica il prossimo appuntamento
    }
  }

  Future<void> _takeMedication() async {
    if (_nextMedication != null) {
      // Aggiorna la prossima dose per il farmaco
      // Utilizza il metodo toCompanion generato per creare un Companion da un modello esistente
      final updatedMedicationCompanion = _nextMedication!.toCompanion(true).copyWith(
        nextDose: Value(_nextMedication!.nextDose!.add(const Duration(days: 1))), // Esempio: prossima dose tra 1 giorno
      );
      await widget.db.updateMedication(updatedMedicationCompanion);

      await widget.db.addHistoryEntry(
        HistoryEntriesCompanion(
          userId: Value(widget.userId),
          timestamp: Value(DateTime.now()),
          type: const Value('medication_taken'),
          description: Value('Farmaco preso: ${_nextMedication!.name} - Dose: ${_nextMedication!.dosage}'),
        ),
      );
      _loadNextMedication(); // Ricarica il prossimo farmaco
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segreteria Medica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage(db: widget.db, userId: widget.userId)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Prossimi Appuntamenti'),
            _nextAppointment == null
                ? const Text('Nessun appuntamento imminente.')
                : Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nextAppointment!.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(_nextAppointment!.appointmentDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (_nextAppointment!.description != null && _nextAppointment!.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Descrizione: ${_nextAppointment!.description}',
                                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: _completeAppointment,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Completato'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _cancelAppointment,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Annulla'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
            _buildSectionTitle('Prossimi Farmaci'),
            _nextMedication == null
                ? const Text('Nessun farmaco imminente.')
                : Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nextMedication!.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_nextMedication!.dosage != null && _nextMedication!.dosage!.isNotEmpty)
                            Text(
                              'Dosaggio: ${_nextMedication!.dosage}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          if (_nextMedication!.frequency != null && _nextMedication!.frequency!.isNotEmpty)
                            Text(
                              'Frequenza: ${_nextMedication!.frequency}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          if (_nextMedication!.nextDose != null)
                            Text(
                              'Prossima dose: ${DateFormat('dd/MM/yyyy HH:mm').format(_nextMedication!.nextDose!)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              onPressed: _takeMedication,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              child: const Text('Prendi Farmaco'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
            _buildSectionTitle('Accesso Rapido'),
            _buildQuickAccessGrid(),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.calendar_today),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: 'Nuovo Appuntamento',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppointmentsPage(db: widget.db, userId: widget.userId)),
              ).then((_) => _loadNextAppointment()); // Ricarica dopo aver aggiunto/modificato
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.medical_services),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Nuovo Farmaco',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicationsPage(db: widget.db, userId: widget.userId)),
              ).then((_) => _loadNextMedication()); // Ricarica dopo aver aggiunto/modificato
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        _buildQuickAccessCard(
          icon: Icons.calendar_month,
          title: 'Appuntamenti',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AppointmentsPage(db: widget.db, userId: widget.userId)),
            );
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.medication,
          title: 'Farmaci',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MedicationsPage(db: widget.db, userId: widget.userId)),
            );
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.history,
          title: 'Cronologia',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HistoryPage(db: widget.db, userId: widget.userId)),
            );
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.settings,
          title: 'Impostazioni',
          onTap: () {
            // TODO: Implementare la pagina delle impostazioni
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funzionalità Impostazioni non ancora implementata.')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
