import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/models/models.dart'; // Assicurati di importare i modelli

class ProfileSelectionDialog extends StatefulWidget {
const ProfileSelectionDialog({super.key});

@override
State\<ProfileSelectionDialog\> createState() =\> \_ProfileSelectionDialogState();
}

class \_ProfileSelectionDialogState extends State\<ProfileSelectionDialog\> {
final TextEditingController \_nameController = TextEditingController();
final TextEditingController \_codFisController = TextEditingController(); // Usare codFis per coerenza
final TextEditingController \_phoneNumberController = TextEditingController();
final TextEditingController \_emailController = TextEditingController(); // Aggiungi controller per email

Profile? \_editingProfile;

void \_clearControllers() {
\_nameController.clear();
\_codFisController.clear();
\_phoneNumberController.clear();
\_emailController.clear(); // Clear anche email
\_editingProfile = null;
}

void \_loadProfileForEditing(Profile profile) {
setState(() {
\_editingProfile = profile;
\_nameController.text = profile.name;
\_codFisController.text = profile.codFis; // Usa codFis
\_phoneNumberController.text = profile.phoneNumber;
\_emailController.text = profile.email ?? ''; // Carica email, se null stringa vuota
});
}

Future\<void\> \_saveProfile(BuildContext context) async {
final appProvider = Provider.of\<AppProvider\>(context, listen: false);

```
if (_nameController.text.isEmpty ||
    _codFisController.text.isEmpty ||
    _phoneNumberController.text.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Per favore, compila tutti i campi obbligatori.')),
  );
  return;
}

if (_editingProfile == null) {
  // Nuovo profilo
  final newProfile = Profile(
    name: _nameController.text,
    codFis: _codFisController.text, // Usa codFis
    phoneNumber: _phoneNumberController.text,
    email: _emailController.text.isEmpty ? null : _emailController.text, // Salva email
  );
  await appProvider.addProfile(newProfile);
} else {
  // Modifica profilo esistente
  final updatedProfile = _editingProfile!.copyWith(
    name: _nameController.text,
    codFis: _codFisController.text, // Usa codFis
    phoneNumber: _phoneNumberController.text,
    email: _emailController.text.isEmpty ? null : _emailController.text, // Salva email
  );
  await appProvider.updateProfile(updatedProfile);
}
_clearControllers();
if (mounted) Navigator.of(context).pop(); // Chiudi il dialog dopo aver salvato
```

}

Future\<void\> \_deleteProfile(BuildContext context, Profile profile) async {
final appProvider = Provider.of\<AppProvider\>(context, listen: false);
final confirm = await showDialog\<bool\>(
context: context,
builder: (ctx) =\> AlertDialog(
title: const Text('Conferma Eliminazione'),
content: Text('Sei sicuro di voler eliminare il profilo di ${profile.name}?'),
actions: \<Widget\>[
TextButton(
onPressed: () =\> Navigator.of(ctx).pop(false),
child: const Text('Annulla'),
),
TextButton(
onPressed: () =\> Navigator.of(ctx).pop(true),
child: const Text('Elimina'),
),
],
),
);

```
if (confirm == true) {
  await appProvider.deleteProfile(profile.codFis); // Passa codFis o phoneNumber, non l'oggetto Profile
  _clearControllers();
  if (mounted) Navigator.of(context).pop(); // Chiudi il dialog dopo aver eliminato
}
```

}

@override
Widget build(BuildContext context) {
return Consumer\<AppProvider\>(
builder: (context, appProvider, child) {
return AlertDialog(
title: const Text('Seleziona Profilo'),
content: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
// Lista dei profili esistenti
if (appProvider.profiles.isEmpty)
const Text('Nessun profilo salvato. Aggiungine uno nuovo.'),
...appProvider.profiles.map((profile) =\> ListTile(
title: Text(profile.name),
subtitle: Text('${profile.codFis} - ${profile.phoneNumber}'), // Usa codFis
trailing: Row(
mainAxisSize: MainAxisSize.min,
children: [
IconButton(
icon: const Icon(Icons.edit),
onPressed: () =\> \_loadProfileForEditing(profile),
),
IconButton(
icon: const Icon(Icons.delete),
onPressed: () =\> \_deleteProfile(context, profile),
),
],
),
onTap: () {
appProvider.selectProfile(profile);
Navigator.of(context).pop(); // Chiudi il dialog dopo la selezione
},
)),
const Divider(),
// Form per aggiungere/modificare profilo
Text(\_editingProfile == null ? 'Aggiungi Nuovo Profilo' : 'Modifica Profilo',
style: const TextStyle(fontWeight: FontWeight.bold)),
TextField(
controller: \_nameController,
decoration: const InputDecoration(labelText: 'Nome'),
),
TextField(
controller: \_codFisController, // Usa codFis
decoration: const InputDecoration(labelText: 'Codice Fiscale'),
),
TextField(
controller: \_phoneNumberController,
decoration: const InputDecoration(labelText: 'Numero di Telefono'),
keyboardType: TextInputType.phone,
),
TextField(
controller: \_emailController, // Campo email
decoration: const InputDecoration(labelText: 'Email (Opzionale)'),
keyboardType: TextInputType.emailAddress,
),
const SizedBox(height: 16),
ElevatedButton(
onPressed: () =\> \_saveProfile(context),
child: Text(\_editingProfile == null ? 'Aggiungi Profilo' : 'Salva Modifiche'),
),
if (\_editingProfile \!= null) // Pulsante Annulla per modifica
TextButton(
onPressed: \_clearControllers,
child: const Text('Annulla Modifica'),
),
],
),
),
actions: \<Widget\>[
TextButton(
onPressed: () {
\_clearControllers();
Navigator.of(context).pop();
},
child: const Text('Chiudi'),
),
],
);
},
);
}
}
