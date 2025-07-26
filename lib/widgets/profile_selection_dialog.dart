// lib/widgets/profile_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/custom_snackbar.dart'; // Added for showing messages

class ProfileSelectionDialog extends StatefulWidget {
  const ProfileSelectionDialog({super.key});

  @override
  State<ProfileSelectionDialog> createState() => _ProfileSelectionDialogState();
}

class _ProfileSelectionDialogState extends State<ProfileSelectionDialog> {
  final _nameController = TextEditingController();
  final _fiscalCodeController = TextEditingController(); // This controller is for codFis
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController(); // Added email controller
  Profile? _editingProfile;

  @override
  void dispose() {
    _nameController.dispose();
    _fiscalCodeController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose(); // Dispose email controller
    super.dispose();
  }

  void _saveProfile(BuildContext context) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Basic validation
    if (_nameController.text.isEmpty ||
        _fiscalCodeController.text.isEmpty ||
        _phoneNumberController.text.isEmpty) {
      CustomSnackBar.show(context, 'Tutti i campi obbligatori devono essere compilati.', isError: true);
      return;
    }

    if (_editingProfile == null) {
      // Add new profile
      final newProfile = Profile(
        name: _nameController.text,
        codFis: _fiscalCodeController.text,
        phoneNumber: _phoneNumberController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );
      await appProvider.addProfile(newProfile);
      CustomSnackBar.show(context, 'Profilo aggiunto con successo!');
    } else {
      // Update existing profile
      final updatedProfile = _editingProfile!.copyWith(
        name: _nameController.text,
        codFis: _fiscalCodeController.text,
        phoneNumber: _phoneNumberController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );
      await appProvider.updateProfile(updatedProfile);
      CustomSnackBar.show(context, 'Profilo aggiornato con successo!');
    }
    Navigator.of(context).pop();
  }

  void _editProfile(Profile profile) {
    setState(() {
      _editingProfile = profile;
      _nameController.text = profile.name;
      _fiscalCodeController.text = profile.codFis;
      _phoneNumberController.text = profile.phoneNumber;
      _emailController.text = profile.email ?? ''; // Set email, handle null
    });
  }

  void _deleteProfile(Profile profile) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    // Add confirmation dialog for deletion
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Profilo'),
        content: Text('Sei sicuro di voler eliminare il profilo di ${profile.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await appProvider.deleteProfile(profile.codFis);
      CustomSnackBar.show(context, 'Profilo eliminato con successo!');
      // If the deleted profile was the selected one, clear selectedProfile
      if (appProvider.selectedProfile?.codFis == profile.codFis) {
        appProvider.selectProfile(null);
      }
      // Refresh the list and potentially close the dialog if no profiles remain or if editing the deleted one
      if (appProvider.profiles.isEmpty || _editingProfile?.codFis == profile.codFis) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestisci Profili'),
      content: SingleChildScrollView(
        child: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (appProvider.profiles.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: appProvider.profiles.length,
                    itemBuilder: (context, index) {
                      final profile = appProvider.profiles[index];
                      return ListTile(
                        title: Text(profile.name),
                        subtitle: Text('${profile.codFis} - ${profile.phoneNumber}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editProfile(profile),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteProfile(profile),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Corrected: Use selectProfile method
                          appProvider.selectProfile(profile);
                          Navigator.of(context).pop(); // Close dialog after selection
                          CustomSnackBar.show(context, 'Profilo ${profile.name} selezionato.');
                        },
                      );
                    },
                  ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                ),
                TextField(
                  controller: _fiscalCodeController,
                  decoration: const InputDecoration(labelText: 'Codice Fiscale'),
                ),
                TextField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Numero di Telefono'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email (Opzionale)'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Clear current editing state
            setState(() {
              _editingProfile = null;
              _nameController.clear();
              _fiscalCodeController.clear();
              _phoneNumberController.clear();
              _emailController.clear();
            });
          },
          child: const Text('Nuovo Profilo'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Chiudi'),
        ),
        ElevatedButton(
          onPressed: () => _saveProfile(context),
          child: Text(_editingProfile == null ? 'Aggiungi Profilo' : 'Aggiorna Profilo'),
        ),
      ],
    );
  }
}