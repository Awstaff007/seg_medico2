import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:uuid/uuid.dart';

class ProfileSelectionDialog extends StatefulWidget {
  const ProfileSelectionDialog({Key? key}) : super(key: key);

  @override
  _ProfileSelectionDialogState createState() => _ProfileSelectionDialogState();
}

class _ProfileSelectionDialogState extends State<ProfileSelectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codFisController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  Profile? _editingProfile;

  @override
  void dispose() {
    _nameController.dispose();
    _codFisController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _editProfile(Profile profile) {
    setState(() {
      _editingProfile = profile;
      _nameController.text = profile.name;
      _codFisController.text = profile.codFis;
      _phoneController.text = profile.phone;
      _emailController.text = profile.email ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      _editingProfile = null;
      _formKey.currentState?.reset();
      _nameController.clear();
      _codFisController.clear();
      _phoneController.clear();
      _emailController.clear();
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final profile = Profile(
        id: _editingProfile?.id ?? const Uuid().v4(),
        name: _nameController.text,
        codFis: _codFisController.text.toUpperCase(),
        phone: _phoneController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
      );
      await appProvider.addProfile(profile);
      _clearForm();
    }
  }

  void _deleteProfile(String profileId) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.deleteProfile(profileId);
    if (_editingProfile?.id == profileId) {
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final profiles = appProvider.getProfiles();

    return AlertDialog(
      title: Text(_editingProfile == null ? 'Aggiungi Profilo' : 'Modifica Profilo'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome e Cognome'),
                      validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
                    ),
                    TextFormField(
                      controller: _codFisController,
                      decoration: const InputDecoration(labelText: 'Codice Fiscale'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefono'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
                    ),
                     TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email (Opzionale)'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (profiles.isNotEmpty) ...[
                const Divider(),
                const Text("Profili Esistenti", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    final isDefault = appProvider.currentProfile?.id == profile.id;
                    return ListTile(
                      title: Text(profile.name),
                      subtitle: Text(profile.codFis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editProfile(profile),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                            onPressed: () => _deleteProfile(profile.id),
                          ),
                        ],
                      ),
                      leading: isDefault ? Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.person),
                      onTap: () {
                         appProvider.switchProfile(profile.id);
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_editingProfile != null)
         TextButton(
          onPressed: _clearForm,
          child: const Text('ANNULLA MODIFICA'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CHIUDI'),
        ),
        ElevatedButton(
          onPressed: _saveProfile,
          child: const Text('SALVA'),
        ),
      ],
    );
  }
}
