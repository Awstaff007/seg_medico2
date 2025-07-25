// lib/widgets/profile\_management\_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg\_medico/models/models.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/widgets/custom\_snackbar.dart';

class ProfileManagementDialog extends StatefulWidget {
final Function(Profile?) onProfileSelected;

const ProfileManagementDialog({super.key, required this.onProfileSelected});

@override
State\<ProfileManagementDialog\> createState() =\> \_ProfileManagementDialogState();
}

class \_ProfileManagementDialogState extends State\<ProfileManagementDialog\> {
final TextEditingController \_nameController = TextEditingController();
final TextEditingController \_codFisController = TextEditingController();
final TextEditingController \_phoneController = TextEditingController();
Profile? \_editingProfile;

@override
void dispose() {
\_nameController.dispose();
\_codFisController.dispose();
\_phoneController.dispose();
super.dispose();
}

void \_clearFields() {
\_nameController.clear();
\_codFisController.clear();
\_phoneController.clear();
setState(() {
\_editingProfile = null;
});
}

void \_editProfile(Profile profile) {
\_nameController.text = profile.name;
\_codFisController.text = profile.codFis;
\_phoneController.text = profile.phoneNumber;
setState(() {
\_editingProfile = profile;
});
}

Future\<void\> \_saveProfile() async {
final appProvider = Provider.of\<AppProvider\>(context, listen: false);
if (\_nameController.text.isEmpty || \_codFisController.text.isEmpty || \_phoneController.text.isEmpty) {
CustomSnackBar.show(context, 'Tutti i campi sono obbligatori.', isError: true);
return;
}

```
final newProfile = Profile(
  name: _nameController.text,
  codFis: _codFisController.text,
  phoneNumber: _phoneController.text,
);

if (_editingProfile == null) {
  await appProvider.addProfile(newProfile);
  CustomSnackBar.show(context, 'Profilo aggiunto con successo!');
} else {
  await appProvider.updateProfile(newProfile);
  CustomSnackBar.show(context, 'Profilo aggiornato con successo!');
}
_clearFields();
Navigator.of(context).pop(); // Close the dialog after saving
```

}

Future\<void\> \_deleteProfile(String codFis) async {
final appProvider = Provider.of\<AppProvider\>(context, listen: false);
final confirm = await showDialog\<bool\>(
context: context,
builder: (context) =\> AlertDialog(
title: const Text('Conferma eliminazione'),
content: const Text('Sei sicuro di voler eliminare questo profilo?'),
actions: [
TextButton(
onPressed: () =\> Navigator.of(context).pop(false),
child: const Text('No'),
),
TextButton(
onPressed: () =\> Navigator.of(context).pop(true),
child: const Text('Sì'),
),
],
),
);
if (confirm == true) {
await appProvider.deleteProfile(codFis);
CustomSnackBar.show(context, 'Profilo eliminato.');
\_clearFields();
Navigator.of(context).pop(); // Close the dialog after deletion
}
}

@override
Widget build(BuildContext context) {
return AlertDialog(
title: const Text('Gestisci Profili'),
content: Consumer\<AppProvider\>(
builder: (context, appProvider, child) {
return SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
TextField(
controller: \_nameController,
decoration: const InputDecoration(labelText: 'Nome Profilo'),
),
TextField(
controller: \_codFisController,
decoration: const InputDecoration(labelText: 'Codice Fiscale'),
),
TextField(
controller: \_phoneController,
keyboardType: TextInputType.phone,
decoration: const InputDecoration(labelText: 'Numero di Telefono'),
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
ElevatedButton(
onPressed: \_saveProfile,
child: Text(\_editingProfile == null ? 'Aggiungi' : 'Aggiorna'),
),
if (\_editingProfile \!= null)
ElevatedButton(
onPressed: \_clearFields,
child: const Text('Nuovo'),
),
],
),
const Divider(),
const Text('Profili Esistenti:', style: TextStyle(fontWeight: FontWeight.bold)),
if (appProvider.profiles.isEmpty)
const Text('Nessun profilo salvato.')
else
...appProvider.profiles.map((profile) {
return ListTile(
title: Text(profile.name),
subtitle: Text('${profile.codFis} - ${profile.phoneNumber}'),
trailing: Row(
mainAxisSize: MainAxisSize.min,
children: [
IconButton(
icon: const Icon(Icons.edit),
onPressed: () =\> \_editProfile(profile),
),
IconButton(
icon: const Icon(Icons.delete),
onPressed: () =\> \_deleteProfile(profile.codFis),
),
],
),
onTap: () {
widget.onProfileSelected(profile);
Navigator.of(context).pop(); // Close dialog after selection
},
);
}).toList(),
],
),
);
},
),
actions: [
TextButton(
onPressed: () {
Navigator.of(context).pop();
},
child: const Text('Chiudi'),
),
],
);
}
}