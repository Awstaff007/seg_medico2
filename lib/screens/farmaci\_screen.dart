// lib/screens/farmaci\_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/widgets/custom\_snackbar.dart';

class FarmaciScreen extends StatefulWidget {
const FarmaciScreen({super.key});

@override
State\<FarmaciScreen\> createState() =\> \_FarmaciScreenState();
}

class \_FarmaciScreenState extends State\<FarmaciScreen\> {
bool \_isEditing = false;
final TextEditingController \_notesController = TextEditingController();
List\<String\> \_selectedFarmaci = []; // Example: list of selected medications
final List\<String\> \_availableFarmaci = [
'Farmaco 1',
'Farmaco 2',
'Farmaco 3',
'Farmaco 4',
]; // Example: list of available medications

@override
void initState() {
super.initState();
// Load initial notes if any, from a persistent storage (e.g., SharedPreferences)
// For now, it's a placeholder.
\_notesController.text = "Ho aumentato il dosaggio di integratori.";
}

@override
void dispose() {
\_notesController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('FARMACI'),
actions: [
IconButton(
icon: const Icon(Icons.text\_fields),
onPressed: () {
CustomSnackBar.show(context, 'Funzionalità cambio dimensione caratteri non implementata.');
},
),
Consumer\<AppProvider\>(
builder: (context, appProvider, child) {
return DropdownButtonHideUnderline(
child: DropdownButton\<Profile\>(
value: appProvider.selectedProfile,
hint: const Text('Seleziona profilo'),
onChanged: (Profile? newProfile) {
appProvider.selectProfile(newProfile);
},
items: appProvider.profiles.map((Profile profile) {
return DropdownMenuItem\<Profile\>(
value: profile,
child: Text(profile.name),
);
}).toList(),
),
);
},
),
Consumer\<AppProvider\>(
builder: (context, appProvider, child) {
return ElevatedButton(
onPressed: () async {
await appProvider.logout();
CustomSnackBar.show(context, 'Logout effettuato.');
Navigator.of(context).popUntil((route) =\> route.isFirst);
},
child: const Text('Esci'),
);
},
),
],
),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Align(
alignment: Alignment.centerRight,
child: ElevatedButton(
onPressed: () {
setState(() {
\_isEditing = \!\_isEditing;
});
},
child: Text(\_isEditing ? 'Salva Modifiche' : 'Modifica'),
),
),
const SizedBox(height: 16),
...\_availableFarmaci.map((farmaco) {
return CheckboxListTile(
title: Text(farmaco),
value: \_selectedFarmaci.contains(farmaco),
onChanged: \_isEditing
? (bool? newValue) {
setState(() {
if (newValue == true) {
\_selectedFarmaci.add(farmaco);
} else {
\_selectedFarmaci.remove(farmaco);
}
});
}
: null, // Disable checkbox if not in editing mode
);
}).toList(),
const SizedBox(height: 20),
ExpansionTile(
title: const Text('Note personali'),
children: [
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16.0),
child: TextField(
controller: \_notesController,
maxLines: 3,
enabled: \_isEditing,
decoration: const InputDecoration(
border: OutlineInputBorder(),
hintText: 'Aggiungi note personali...',
),
),
),
],
),
const Spacer(),
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
Expanded(
child: ElevatedButton(
onPressed: () async {
if (\_selectedFarmaci.isEmpty) {
CustomSnackBar.show(context, 'Seleziona almeno un farmaco da ordinare.', isError: true);
return;
}
final appProvider = Provider.of\<AppProvider\>(context, listen: false);
if (appProvider.selectedProfile == null) {
CustomSnackBar.show(context, 'Seleziona un profilo per ordinare i farmaci.', isError: true);
return;
}

```
                  final testoFarmaci = _selectedFarmaci.join(', ');
                  final phoneNumber = appProvider.selectedProfile!.phoneNumber;
                  final email = appProvider.selectedProfile!.codFis; // Assuming codFis can be used as email for this API

                  final success = await appProvider.orderFarmaci(testoFarmaci, phoneNumber, email);

                  if (success) {
                    CustomSnackBar.show(context, 'Ordine farmaci inviato con successo!');
                    setState(() {
                      _selectedFarmaci.clear(); // Clear selected items after ordering
                      _isEditing = false; // Exit editing mode
                    });
                  } else {
                    CustomSnackBar.show(context, 'Errore durante l\'invio dell\'ordine. Riprova.', isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('ORDINA'),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _selectedFarmaci.clear(); // Clear selections on cancel
                    // Reset notes to original if implemented
                  });
                  Navigator.pop(context); // Go back to home
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('ANNULLA'),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  bottomNavigationBar: BottomAppBar(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String value) {
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            if (!appProvider.isLoggedIn) {
              CustomSnackBar.show(context, 'Accedi per accedere al menu.');
              return;
            }
            switch (value) {
              case 'cronologia':
                Navigator.pushNamed(context, '/cronologia');
                break;
              case 'farmaci':
                // Already on farmaci screen
                break;
              case 'appuntamenti':
                Navigator.pushNamed(context, '/appuntamenti');
                break;
              case 'impostazioni':
                Navigator.pushNamed(context, '/impostazioni');
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'cronologia',
              enabled: Provider.of<AppProvider>(context).isLoggedIn,
              child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Cronologia' : '⦿ Cronologia (dis.)'),
            ),
            PopupMenuItem<String>(
              value: 'farmaci',
              enabled: Provider.of<AppProvider>(context).isLoggedIn,
              child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Farmaci' : '⦿ Farmaci (dis.)'),
            ),
            PopupMenuItem<String>(
              value: 'appuntamenti',
              enabled: Provider.of<AppProvider>(context).isLoggedIn,
              child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Appuntamenti' : '⦿ Appuntamenti (dis.)'),
            ),
            PopupMenuItem<String>(
              value: 'impostazioni',
              enabled: Provider.of<AppProvider>(context).isLoggedIn,
              child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Impostazioni' : '⦿ Impostazioni (dis.)'),
            ),
          ],
        ),
      ],
    ),
  ),
);
```

}
}