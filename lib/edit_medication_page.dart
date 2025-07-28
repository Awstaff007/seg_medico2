// lib/edit_medication_page.dart

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column; // Importa Value da drift
import 'package:seg_medico2/data/database.dart'; // Importa il tuo database

class EditMedicationPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;
  final Medication? existingMedication; // Farmaco esistente da modificare

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
  late TextEditingController _notesController;
  late DateTime _startDate;
  late DateTime _endDate;
  DateTime? _nextDose; // Campo per la prossima dose

  bool get isEditing => widget.existingMedication != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingMedication?.name ?? '');
    _dosageController = TextEditingController(text: widget.existingMedication?.dosage ?? '');
    _frequencyController = TextEditingController(text: widget.existingMedication?.frequency ?? '');
    _notesController = TextEditingController(text: widget.existingMedication?.notes ?? '');
    _startDate = widget.existingMedication?.startDate ?? DateTime.now();
    _endDate = widget.existingMedication?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _nextDose = widget.existingMedication?.nextDose;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30)); // Assicura che la fine sia dopo l'inizio
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate.subtract(const Duration(days: 30)); // Assicura che l'inizio sia prima della fine
          }
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, {required bool isNextDose}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_nextDose ?? DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _nextDose = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final dosage = _dosageController.text.trim();
      final frequency = _frequencyController.text.trim();
      final notes = _notesController.text.trim();

      if (isEditing) {
        // Aggiorna farmaco esistente
        final updatedMedicationCompanion = MedicationsCompanion(
          id: Value(widget.existingMedication!.id), // ID del farmaco da aggiornare
          userId: Value(widget.userId),
          name: Value(name),
          dosage: Value(dosage.isEmpty ? null : dosage), // Incapsula String? con Value()
          frequency: Value(frequency),
          notes: Value(notes),
          startDate: Value(_startDate),
          endDate: Value(_endDate),
          nextDose: Value(_nextDose),
        );
        await widget.db.updateMedication(updatedMedicationCompanion);

        // Registra l'azione nella cronologia
        await widget.db.addHistoryEntry(
          HistoryEntriesCompanion(
            userId: Value(widget.userId),
            timestamp: Value(DateTime.now()),
            type: Value('medication_updated'),
            description: Value('Aggiornato farmaco: $name'),
          ),
        );
      } else {
        // Aggiungi nuovo farmaco
        final newMedicationCompanion = MedicationsCompanion.insert(
          userId: Value(widget.userId),
          name: name, // Drift accetta String direttamente per insert
          dosage: dosage.isEmpty ? null : dosage, // Drift accetta String? direttamente per insert
          frequency: frequency,
          notes: notes,
          startDate: _startDate,
          endDate: _endDate,
          nextDose: _nextDose,
        );
        await widget.db.addMedication(newMedicationCompanion);

        // Registra l'azione nella cronologia
        await widget.db.addHistoryEntry(
          HistoryEntriesCompanion(
            userId: Value(widget.userId),
            timestamp: Value(DateTime.now()),
            type: Value('medication_added'),
            description: Value('Aggiunto farmaco: $name'),
          ),
        );
      }
      Navigator.pop(context, Medication( // Passa l'oggetto Medication completo
        id: isEditing ? widget.existingMedication!.id : 0, // ID fittizio per nuovo, reale per esistente
        userId: widget.userId,
        name: name,
        dosage: dosage,
        frequency: frequency,
        notes: notes,
        startDate: _startDate,
        endDate: _endDate,
        nextDose: _nextDose,
      ));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica Farmaco' : 'Aggiungi Farmaco'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMedication,
          ),
        ],
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
                decoration: const InputDecoration(labelText: 'Dosaggio (es. 10mg, 1 compressa)'),
              ),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(labelText: 'Frequenza (es. 2 volte al giorno, ogni 8 ore)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci la frequenza';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Data Inizio: ${_startDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: true),
              ),
              ListTile(
                title: Text('Data Fine: ${_endDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: false),
              ),
              ListTile(
                title: Text('Prossima Dose: ${_nextDose?.toLocal().toString().split('.')[0] ?? 'Non impostata'}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, isNextDose: true),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMedication,
                child: Text(isEditing ? 'Salva Modifiche' : 'Aggiungi Farmaco'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
