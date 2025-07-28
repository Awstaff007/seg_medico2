// lib/edit_medication_page.dart
import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:drift/drift.dart' hide Column; // Import Value

class EditMedicationPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;
  final Medication? medication; // Null if adding a new medication

  const EditMedicationPage({
    super.key,
    required this.db,
    required this.userId,
    this.medication,
  });

  @override
  State<EditMedicationPage> createState() => _EditMedicationPageState();
}

class _EditMedicationPageState extends State<EditMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  DateTime? _nextDoseDate;
  TimeOfDay? _nextDoseTime;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name);
    _dosageController = TextEditingController(text: widget.medication?.dosage);
    if (widget.medication?.nextDose != null) {
      _nextDoseDate = widget.medication!.nextDose;
      _nextDoseTime = TimeOfDay.fromDateTime(widget.medication!.nextDose!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDoseDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _nextDoseDate) {
      setState(() {
        _nextDoseDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _nextDoseTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _nextDoseTime) {
      setState(() {
        _nextDoseTime = picked;
      });
    }
  }

  Future<void> _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String name = _nameController.text.trim();
      final String dosage = _dosageController.text.trim();
      DateTime? nextDose;
      if (_nextDoseDate != null && _nextDoseTime != null) {
        nextDose = DateTime(
          _nextDoseDate!.year,
          _nextDoseDate!.month,
          _nextDoseDate!.day,
          _nextDoseTime!.hour,
          _nextDoseTime!.minute,
        );
      }

      if (_isEditing) {
        final updatedMedication = widget.medication!.copyWith(
          name: name,
          dosage: dosage.isEmpty ? null : dosage,
          nextDose: Value(nextDose), // Value() is correct here for nullable field
        );
        await widget.db.updateMedication(updatedMedication);

        // Add history entry for update
        await widget.db.insertHistory( // Corrected: insertHistory
          HistoriesCompanion(
            userId: widget.userId, // No Value()
            timestamp: DateTime.now(), // No Value()
            type: 'medication_updated', // No Value()
            description: 'Aggiornato farmaco: $name', // No Value()
            medicationId: Value(widget.medication!.id), // Value() is correct for nullable
          ),
        );
      } else {
        final newMedicationId = await widget.db.insertMedication(
          MedicationsCompanion(
            userId: widget.userId, // No Value()
            name: name, // No Value()
            dosage: dosage.isEmpty ? null : dosage, // No Value()
            nextDose: Value(nextDose), // Value() is correct here for nullable field
          ),
        );
        // Add history entry for addition
        await widget.db.insertHistory( // Corrected: insertHistory
          HistoriesCompanion(
            userId: widget.userId, // No Value()
            timestamp: DateTime.now(), // No Value()
            type: 'medication_added', // No Value()
            description: 'Aggiunto farmaco: $name', // No Value()
            medicationId: Value(newMedicationId), // Value() is correct for nullable
          ),
        );
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Farmaco aggiornato!' : 'Farmaco aggiunto!')),
      );
    }
  }

  Future<void> _deleteMedication() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: Text('Sei sicuro di voler eliminare il farmaco "${widget.medication!.name}"?'),
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
      await widget.db.deleteMedication(widget.medication!); // Pass the full Medication object
      await widget.db.deleteMedicationHistory(widget.medication!.id); // Delete related history entries
      await widget.db.insertHistory( // Corrected: insertHistory
        HistoriesCompanion(
          userId: widget.userId, // No Value()
          timestamp: DateTime.now(), // No Value()
          type: 'medication_deleted', // No Value()
          description: 'Cancellato farmaco: ${widget.medication!.name}', // No Value()
          medicationId: Value(widget.medication!.id), // Value() is correct for nullable
        ),
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Farmaco "${widget.medication!.name}" eliminato.')),
      );
    }
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return 'Seleziona data e ora';
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return '${dt.toLocal().day}/${dt.toLocal().month}/${dt.toLocal().year} ${dt.toLocal().hour}:${dt.toLocal().minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica Farmaco' : 'Aggiungi Farmaco'),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteMedication,
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
                decoration: const InputDecoration(labelText: 'Dosaggio (es. "1 compressa", "5ml")'),
              ),
              ListTile(
                title: Text('Prossima dose: ${_formatDateTime(_nextDoseDate, _nextDoseTime)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  await _selectDate(context);
                  if (_nextDoseDate != null) {
                    await _selectTime(context);
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMedication,
                child: Text(_isEditing ? 'Salva Modifiche' : 'Aggiungi Farmaco'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}