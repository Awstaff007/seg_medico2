import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico2/auth/auth_service.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/edit_medication_page.dart';

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({Key? key}) : super(key: key);

  @override
  _MedicationsPageState createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  late AppDatabase _database;
  late int _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _database = Provider.of<AppDatabase>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = int.parse(authService.currentUserId!);
  }

  Future<void> _deleteMedication(int medicationId, String medicationName) async {
    await _database.deleteMedication(medicationId);
    // CORREZIONE: Usa il metodo e il companion corretti
    await _database.addHistoryEntry(
      MedicalHistoryCompanion(
        userId: Value(_currentUserId),
        eventType: const Value('Farmaco'),
        details: Value('Farmaco eliminato: $medicationName'),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _toggleMedicationStatus(Medication medication) async {
    // CORREZIONE: Usa il campo 'isActive'
    final newStatus = !medication.isActive;
    await _database.updateMedication(MedicationsCompanion(
      id: Value(medication.id),
      // CORREZIONE: Usa il campo 'isActive'
      isActive: Value(newStatus),
    ));

    final details = newStatus
        ? 'Farmaco riattivato: ${medication.name}'
        : 'Farmaco disattivato: ${medication.name}';
    
    // CORREZIONE: Usa il metodo e il companion corretti
    await _database.addHistoryEntry(
      MedicalHistoryCompanion(
        userId: Value(_currentUserId),
        eventType: const Value('Stato Farmaco'),
        details: Value(details),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestione Farmaci')),
      body: StreamBuilder<List<Medication>>(
        // CORREZIONE: Il metodo si chiama 'watchAllMedicationsForUser'
        stream: _database.watchAllMedicationsForUser(_currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final medications = snapshot.data!;
          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return Card(
                child: ListTile(
                  title: Text(
                    medication.name,
                    style: TextStyle(
                      // CORREZIONE: Usa 'isActive'
                      decoration: !medication.isActive ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dosaggio: ${medication.dosage}'),
                      Text('Frequenza: ${medication.frequency}'),
                      // CORREZIONE: Usa 'nextDose'
                      if (medication.nextDose != null)
                        Text('Prossima dose: ${DateFormat('dd/MM/yyyy HH:mm').format(medication.nextDose!)}'),
                    ],
                  ),
                  leading: IconButton(
                    icon: Icon(
                      // CORREZIONE: Usa 'isActive'
                      medication.isActive ? Icons.toggle_on : Icons.toggle_off,
                      // CORREZIONE: Usa 'isActive'
                      color: medication.isActive ? Colors.green : Colors.red,
                      size: 40,
                    ),
                    onPressed: () => _toggleMedicationStatus(medication),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => EditMedicationPage(
                              db: _database,
                              userId: _currentUserId,
                              existingMedication: medication,
                            ),
                          ));
                        },
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
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => EditMedicationPage(
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
