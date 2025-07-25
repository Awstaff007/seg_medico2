// lib/screens/appuntamenti\_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:seg\_medico/models/models.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/widgets/custom\_snackbar.dart';

class AppuntamentiScreen extends StatefulWidget {
const AppuntamentiScreen({super.key});

@override
State\<AppuntamentiScreen\> createState() =\> \_AppuntamentiScreenState();
}

class \_AppuntamentiScreenState extends State\<AppuntamentiScreen\> {
List\<AppointmentSlot\> \_availableSlots = [];
bool \_isLoadingSlots = false;
String? \_selectedSlot;
final TextEditingController \_notesController = TextEditingController();

@override
void initState() {
super.initState();
\_fetchAvailableSlots();
}

Future\<void\> \_fetchAvailableSlots() async {
setState(() {
\_isLoadingSlots = true;
\_availableSlots = [];
\_selectedSlot = null;
});

```
final appProvider = Provider.of<AppProvider>(context, listen: false);
final userInfo = appProvider.userInfo;

if (userInfo != null && userInfo.ambulatori.isNotEmpty) {
  final ambulatorioId = userInfo.ambulatori.first.id; // Assuming the first ambulatorio
  final slots = await appProvider.getAppointmentSlots(ambulatorioId, 1); // Request 1 slot
  setState(() {
    _availableSlots = slots;
    _isLoadingSlots = false;
  });
} else {
  setState(() {
    _isLoadingSlots = false;
  });
  CustomSnackBar.show(context, 'Nessun ambulatorio disponibile o informazioni utente mancanti.', isError: true);
}
```

}

Future\<void\> \_bookAppointment() async {
if (\_selectedSlot == null) {
CustomSnackBar.show(context, 'Seleziona uno slot disponibile per prenotare.', isError: true);
return;
}

```
final appProvider = Provider.of<AppProvider>(context, listen: false);
final userInfo = appProvider.userInfo;
final selectedProfile = appProvider.selectedProfile;

if (userInfo == null || selectedProfile == null || userInfo.ambulatori.isEmpty) {
  CustomSnackBar.show(context, 'Informazioni utente o profilo non disponibili.', isError: true);
  return;
}

final ambulatorioId = userInfo.ambulatori.first.id;
final parts = _selectedSlot!.split(' – ');
final datePart = parts[0];
final timePart = parts[1];

final data = DateFormat('dd MMM yyyy').parse(datePart);
final formattedDate = DateFormat('yyyy/MM/dd').format(data);
final inizio = timePart;
final fine = DateFormat('HH:mm').format(DateFormat('HH:mm').parse(timePart).add(const Duration(minutes: 10))); // Assuming 10 min duration

final success = await appProvider.bookAppointment(
  ambulatorioId: ambulatorioId,
  numero: 1, // Booking 1 slot
  data: formattedDate,
  inizio: inizio,
  fine: fine,
  telefono: selectedProfile.phoneNumber,
  email: selectedProfile.codFis, // Using codFis as email for this API
);

if (success) {
  CustomSnackBar.show(context, 'Appuntamento prenotato con successo!');
  _notesController.clear(); // Clear notes after booking
  Navigator.pop(context); // Go back to home
} else {
  CustomSnackBar.show(context, 'Errore durante la prenotazione. Riprova.', isError: true);
}
```

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
title: const Text('APPUNTAMENTI'),
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
const Text(
'Disponibilità via API:',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
\_isLoadingSlots
? const Center(child: CircularProgressIndicator())
: \_availableSlots.isEmpty
? const Text('Nessuna disponibilità trovata.')
: Expanded(
child: ListView.builder(
itemCount: \_availableSlots.length,
itemBuilder: (context, index) {
final slot = \_availableSlots[index];
final displayDate = DateFormat('dd MMM yyyy').format(DateTime.parse(slot.data));
final displayText = '$displayDate – ${slot.inizio}';
return RadioListTile\<String\>(
title: Text(displayText),
value: displayText,
groupValue: \_selectedSlot,
onChanged: (String? value) {
setState(() {
\_selectedSlot = value;
});
},
);
},
),
),
const SizedBox(height: 20),
const Text(
'✏️ Note visita:',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
TextField(
controller: \_notesController,
maxLines: 3,
decoration: const InputDecoration(
border: OutlineInputBorder(),
hintText: 'Aggiungi note per la visita...',
),
),
const Spacer(),
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
Expanded(
child: ElevatedButton(
onPressed: \_selectedSlot \!= null ? \_bookAppointment : null,
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 15),
textStyle: const TextStyle(fontSize: 18),
),
child: const Text('PRENOTA'),
),
),
const SizedBox(width: 20),
Expanded(
child: ElevatedButton(
onPressed: () {
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
PopupMenuButton\<String\>(
icon: const Icon(Icons.more\_vert),
onSelected: (String value) {
final appProvider = Provider.of\<AppProvider\>(context, listen: false);
if (\!appProvider.isLoggedIn) {
CustomSnackBar.show(context, 'Accedi per accedere al menu.');
return;
}
switch (value) {
case 'cronologia':
Navigator.pushNamed(context, '/cronologia');
break;
case 'farmaci':
Navigator.pushNamed(context, '/farmaci');
break;
case 'appuntamenti':
// Already on appuntamenti screen
break;
case 'impostazioni':
Navigator.pushNamed(context, '/impostazioni');
break;
}
},
itemBuilder: (BuildContext context) =\> \<PopupMenuEntry\<String\>\>[
PopupMenuItem\<String\>(
value: 'cronologia',
enabled: Provider.of\<AppProvider\>(context).isLoggedIn,
child: Text(Provider.of\<AppProvider\>(context).isLoggedIn ? 'Cronologia' : '⦿ Cronologia (dis.)'),
),
PopupMenuItem\<String\>(
value: 'farmaci',
enabled: Provider.of\<AppProvider\>(context).isLoggedIn,
child: Text(Provider.of\<AppProvider\>(context).isLoggedIn ? 'Farmaci' : '⦿ Farmaci (dis.)'),
),
PopupMenuItem\<String\>(
value: 'appuntamenti',
enabled: Provider.of\<AppProvider\>(context).isLoggedIn,
child: Text(Provider.of\<AppProvider\>(context).isLoggedIn ? 'Appuntamenti' : '⦿ Appuntamenti (dis.)'),
),
PopupMenuItem\<String\>(
value: 'impostazioni',
enabled: Provider.of\<AppProvider\>(context).isLoggedIn,
child: Text(Provider.of\<AppProvider\>(context).isLoggedIn ? 'Impostazioni' : '⦿ Impostazioni (dis.)'),
),
],
),
],
),
),
);
}
}