import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:drift/drift.dart' as drift;

class EditAppointmentPage extends StatefulWidget {
  final AppDatabase db;
  final int userId;
  final Appointment? existingAppointment;

  const EditAppointmentPage({
    Key? key,
    required this.db,
    required this.userId,
    this.existingAppointment,
  }) : super(key: key);

  @override
  _EditAppointmentPageState createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _doctorController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  DateTime? _appointmentDate;

  @override
  void initState() {
    super.initState();
    _doctorController = TextEditingController(text: widget.existingAppointment?.doctorName ?? '');
    _locationController = TextEditingController(text: widget.existingAppointment?.location ?? '');
    _notesController = TextEditingController(text: widget.existingAppointment?.notes ?? '');
    _appointmentDate = widget.existingAppointment?.appointmentDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_appointmentDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _appointmentDate = DateTime(
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

  Future<void> _saveAppointment() async {
    if (_formKey.currentState!.validate() && _appointmentDate != null) {
      final companion = AppointmentsCompanion(
        userId: drift.Value(widget.userId),
        doctorName: drift.Value(_doctorController.text),
        location: drift.Value(_locationController.text),
        appointmentDate: drift.Value(_appointmentDate!),
        notes: drift.Value(_notesController.text),
      );

      if (widget.existingAppointment == null) {
        await widget.db.addAppointment(companion);
      } else {
        await widget.db.updateAppointment(companion.copyWith(id: drift.Value(widget.existingAppointment!.id)));
      }
      Navigator.of(context).pop();
    } else if (_appointmentDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Per favore, seleziona una data per l\'appuntamento.'))
        );
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
          child: Column(
            children: [
              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(labelText: 'Nome Medico'),
                validator: (value) => value!.isEmpty ? 'Inserisci il nome del medico' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Luogo'),
                validator: (value) => value!.isEmpty ? 'Inserisci il luogo' : null,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Note (opzionale)'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _appointmentDate == null
                          ? 'Nessuna data selezionata'
                          : 'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(_appointmentDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Seleziona'),
                  )
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAppointment,
                child: const Text('Salva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
