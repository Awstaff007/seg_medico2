// lib/edit_medication_page.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart'; // Questo import ora porta tutti i tipi generati
import 'package:drift/drift.dart' hide Column; // Importa Value da drift
import 'package:intl/intl.dart';

class EditMedicationPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;
  final Medication? existingMedication; // Il tipo Medication è ora riconosciuto

  const EditMedicationPage({
    super.key,
    required this.db,
    required this.userId,
    this.existingMedication,
  });

  @override
  State<EditMedicationPage> createState() => _EditMedicationPageState();
}

class _EditMedicationPageState extends State<EditMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  DateTime? _nextDose; // Può essere null

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingMedication?.name ?? '');
    _dosageController = TextEditingController(text: widget.existingMedication?.dosage ?? '');
    _frequencyController = TextEditingController(text: widget.existingMedication?.frequency ?? '');
    _nextDose = widget.existingMedication?.nextDose;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _selectNextDoseDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _nextDose ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_nextDose ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _nextDose = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final dosage = _dosageController.text;
      final frequency = _frequencyController.text;

      final companion = MedicationsCompanion( // Ora riconosciuto
        userId: Value(widget.userId),
        name: Value(name),
        dosage: Value(dosage.isEmpty ? null : dosage),
        frequency: Value(frequency.isEmpty ? null : frequency),
        nextDose: Value(_nextDose),
        isActive: Value(widget.existingMedication?.isActive ?? true),
      );

      if (widget.existingMedication == null) {
        await widget.db.addMedication(companion);
        await widget.db.addHistoryEntry(
          HistoryEntriesCompanion( // Ora riconosciuto
            userId: Value(widget.userId),
            timestamp: Value(DateTime.now()),
            type: const Value('medication_added'),
            description: Value('Nuovo farmaco aggiunto: $name'),
          ),
        );
      } else {
        await widget.db.updateMedication(companion.copyWith(id: Value(widget.existingMedication!.id)));
        await widget.db.addHistoryEntry(
          HistoryEntriesCompanion( // Ora riconosciuto
            userId: Value(widget.userId),
            timestamp: Value(DateTime.now()),
            type: const Value('medication_updated'),
            description: Value('Farmaco aggiornato: $name'),
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
        title: Text(widget.existingMedication == null ? 'Nuovo Farmaco' : 'Modifica Farmaco'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Farmaco'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il nome del farmaco';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosaggio (es. 5mg, 1 compressa)'),
              ),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(labelText: 'Frequenza (es. 2 volte al giorno, ogni 8 ore)'),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(
                  _nextDose == null
                      ? 'Seleziona Prossima Dose'
                      : 'Prossima Dose: ${DateFormat('dd/MM/yyyy HH:mm').format(_nextDose!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectNextDoseDateTime(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMedication,
                child: Text(widget.existingMedication == null ? 'Aggiungi Farmaco' : 'Salva Modifiche'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
