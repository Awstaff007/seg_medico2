// lib/pages/add_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/profile.dart';
import 'package:seg_medico/providers/app_provider.dart';

class AddProfilePage extends StatefulWidget {
  final Profile? profileToEdit;

  const AddProfilePage({super.key, this.profileToEdit});

  @override
  State<AddProfilePage> createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codiceFiscaleController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _capController;
  late TextEditingController _notesController;
  DateTime? _selectedBirthDate;
  late bool _isEditing;
  late Profile _currentProfile;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.profileToEdit != null;
    _currentProfile = widget.profileToEdit ??
        Profile(
          name: '',
          codiceFiscale: '',
          phoneNumber: '',
          email: '',
          address: '',
          city: '',
          province: '',
          cap: '',
        );

    _nameController = TextEditingController(text: _currentProfile.name);
    _codiceFiscaleController = TextEditingController(text: _currentProfile.codiceFiscale);
    _phoneNumberController = TextEditingController(text: _currentProfile.phoneNumber);
    _emailController = TextEditingController(text: _currentProfile.email);
    _addressController = TextEditingController(text: _currentProfile.address);
    _cityController = TextEditingController(text: _currentProfile.city);
    _provinceController = TextEditingController(text: _currentProfile.province);
    _capController = TextEditingController(text: _currentProfile.cap);
    _notesController = TextEditingController(text: _currentProfile.notes);
    _selectedBirthDate = _currentProfile.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codiceFiscaleController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _capController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      _currentProfile.name = _nameController.text;
      _currentProfile.codiceFiscale = _codiceFiscaleController.text;
      _currentProfile.phoneNumber = _phoneNumberController.text;
      _currentProfile.email = _emailController.text;
      _currentProfile.address = _addressController.text;
      _currentProfile.city = _cityController.text;
      _currentProfile.province = _provinceController.text;
      _currentProfile.cap = _capController.text;
      _currentProfile.notes = _notesController.text;
      _currentProfile.birthDate = _selectedBirthDate;

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.saveProfile(_currentProfile);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica Profilo' : 'Aggiungi Nuovo Profilo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Profilo',
                  hintText: 'Es: Mario Rossi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Il nome del profilo non può essere vuoto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _codiceFiscaleController,
                decoration: const InputDecoration(
                  labelText: 'Codice Fiscale',
                  hintText: 'Es: RSSMRA80A01H501Z',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Il codice fiscale non può essere vuoto';
                  }
                  if (value.length != 16) {
                    return 'Il codice fiscale deve avere 16 caratteri';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numero di Telefono',
                  hintText: 'Es: +393331234567',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Il numero di telefono non può essere vuoto';
                  }
                  // Regex per validare un numero di telefono (semplificato)
                  if (!RegExp(r'^\+?[0-9]{6,15}$').hasMatch(value)) {
                    return 'Inserisci un numero di telefono valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Es: mario.rossi@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'email non può essere vuota';
                  }
                  // Regex per validare un'email (semplificato)
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Inserisci un\'email valida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Indirizzo',
                  hintText: 'Es: Via Roma 10',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'indirizzo non può essere vuoto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Città',
                  hintText: 'Es: Milano',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La città non può essere vuota';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _provinceController,
                decoration: const InputDecoration(
                  labelText: 'Provincia',
                  hintText: 'Es: MI',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La provincia non può essere vuota';
                  }
                  if (value.length != 2) {
                    return 'La provincia deve avere 2 caratteri';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _capController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CAP',
                  hintText: 'Es: 20100',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Il CAP non può essere vuoto';
                  }
                  if (value.length != 5 || !RegExp(r'^[0-9]{5}$').hasMatch(value)) {
                    return 'Inserisci un CAP valido di 5 cifre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _selectedBirthDate == null
                          ? ''
                          : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Data di Nascita',
                      hintText: 'Seleziona data',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (_selectedBirthDate == null) {
                        return 'Seleziona una data di nascita';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Aggiungi note sul profilo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(_isEditing ? 'Salva Modifiche' : 'Crea Profilo'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16.0),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Conferma Eliminazione'),
                          content: Text('Sei sicuro di voler eliminare il profilo "${_currentProfile.name}"?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Annulla'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                              onPressed: () async {
                                final appProvider = Provider.of<AppProvider>(context, listen: false);
                                await appProvider.deleteProfile(_currentProfile.id);
                                Navigator.of(dialogContext).pop();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Elimina Profilo'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
