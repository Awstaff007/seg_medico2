// lib/medications_page.dart
import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/main.dart'; // Import main.dart to access getCurrentUserId
import 'package:seg_medico2/pages/edit_medication_page.dart'; // Import EditMedicationPage
import 'package:drift/drift.dart' hide Column; // Import Value from drift

class MedicationsPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const MedicationsPage({super.key, required this.db, required this.userId});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  late AppDatabase _db;
  late String _currentUserId;
  late Stream<List<Medication>> _medicationsStream;
  Profile? _userProfile;

  @override
  void initState() {
    super.initState();
    _db = widget.db;
    _currentUserId = widget.userId;
    _loadProfileAndMedications();
  }

  Future<void> _loadProfileAndMedications() async {
    _db.watchProfileForUser(_currentUserId).listen((profile) {
      if (profile != null) {
        setState(() {
          _userProfile = profile;
        });
      }
    });
    _medicationsStream = _db.watchMedicationsForUser(_currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final double fontSizeScale = _userProfile?.granularFontSizeScale ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('I Miei Farmaci'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Medication>>(
        stream: _medicationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Nessun farmaco aggiunto. Premi "+" per aggiungerne uno.',
                style: TextStyle(fontSize: 18 * fontSizeScale),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final medications = snapshot.data!;
            return ListView.builder(
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final medication = medications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      medication.name,
                      style: TextStyle(fontSize: 20 * fontSizeScale, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (medication.dosage != null && medication.dosage!.isNotEmpty)
                          Text(
                            'Dosaggio: ${medication.dosage}',
                            style: TextStyle(fontSize: 16 * fontSizeScale),
                          ),
                        if (medication.nextDose != null)
                          Text(
                            'Prossima dose: ${_formatDateTime(medication.nextDose!)}',
                            style: TextStyle(fontSize: 16 * fontSizeScale),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditMedicationPage(
                            db: _db,
                            userId: _currentUserId,
                            medication: medication,
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteMedication(medication), // Pass the full object
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditMedicationPage(
                db: _db,
                userId: _currentUserId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.toLocal().day}/${dateTime.toLocal().month}/${dateTime.toLocal().year} ${dateTime.toLocal().hour}:${dateTime.toLocal().minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDeleteMedication(Medication medication) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: Text('Sei sicuro di voler eliminare il farmaco "${medication.name}"?'),
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
      await _db.deleteMedication(medication); // Pass the full object
      await _db.deleteMedicationHistory(medication.id); // Delete related history entries
      await _db.insertHistory( // Corrected: insertHistory
        HistoriesCompanion(
          userId: _currentUserId, // No Value()
          timestamp: DateTime.now(), // No Value()
          type: 'medication_deleted', // No Value()
          description: 'Cancellato farmaco: ${medication.name}', // No Value()
          medicationId: Value(medication.id), // Use Value() for nullable foreign key
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Farmaco "${medication.name}" eliminato.')),
      );
    }
  }
}