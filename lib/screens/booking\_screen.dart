import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/models/models.dart';
import 'package:seg\_medico/widgets/main\_drawer.dart'; // Importa MainDrawer

class BookingScreen extends StatefulWidget {
const BookingScreen({super.key});

@override
State\<BookingScreen\> createState() =\> \_BookingScreenState();
}

class \_BookingScreenState extends State\<BookingScreen\> {
int? \_selectedAmbulatorioId;
int? \_selectedAmbulatorioNumber;
DateTime? \_selectedDate;
String? \_selectedTimeSlot;
List\<AppointmentSlot\> \_availableSlots = [];
bool \_isLoadingSlots = false;
String? \_bookingMessage;

@override
void initState() {
super.initState();
\_fetchAmbulatories();
}

// Metodo per ottenere gli ambulatori disponibili (potrebbe venire da AppProvider o un servizio dedicato)
Future\<void\> \_fetchAmbulatories() async {
// Per ora, useremo un mock. In futuro, potresti voler aggiungere un metodo in AppProvider.
// final appProvider = Provider.of\<AppProvider\>(context, listen: false);
// final ambulatories = await appProvider.getAmbulatories(); // Esempio
setState(() {
// Questi sono dati di esempio. Verranno recuperati dal backend.
// Assicurati che il tuo AppProvider abbia un metodo per recuperare gli ambulatori.
// Per adesso, usiamo un placeholder.
\_selectedAmbulatorioId = 1; // ID di esempio per il primo ambulatorio
\_selectedAmbulatorioNumber = 101; // Numero di esempio per il primo ambulatorio
});
\_fetchAppointmentSlots(); // Inizializza con slot predefiniti se un ambulatorio è selezionato
}

Future\<void\> \_fetchAppointmentSlots() async {
if (\_selectedAmbulatorioId == null || \_selectedAmbulatorioNumber == null) {
return; // Non posso recuperare slot senza un ambulatorio selezionato
}
setState(() {
\_isLoadingSlots = true;
\_availableSlots = [];
\_selectedTimeSlot = null; // Reset dello slot selezionato
});
try {
final appProvider = Provider.of\<AppProvider\>(context, listen: false);
// AppProvider.getAppointmentSlots richiede ambulatorioId e numero
final slots = await appProvider.getAppointmentSlots(\_selectedAmbulatorioId\!, \_selectedAmbulatorioNumber\!);
setState(() {
\_availableSlots = slots;
});
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Errore nel caricamento degli slot: ${e.toString()}')),
);
} finally {
setState(() {
\_isLoadingSlots = false;
});
}
}

Future\<void\> \_selectDate(BuildContext context) async {
final DateTime? picked = await showDatePicker(
context: context,
initialDate: \_selectedDate ?? DateTime.now(),
firstDate: DateTime.now(),
lastDate: DateTime.now().add(const Duration(days: 365)),
);
if (picked \!= null && picked \!= \_selectedDate) {
setState(() {
\_selectedDate = picked;
\_selectedTimeSlot = null; // Reset dello slot selezionato quando la data cambia
});
// Potresti voler ricaricare gli slot per la data selezionata qui
// \_fetchAppointmentSlots(date: \_selectedDate);
}
}

Future\<void\> \_bookAppointment() async {
if (\_selectedAmbulatorioId == null ||
\_selectedAmbulatorioNumber == null ||
\_selectedDate == null ||
\_selectedTimeSlot == null) {
setState(() {
\_bookingMessage = 'Per favore, seleziona tutti i dettagli della prenotazione.';
});
return;
}

```
setState(() {
  _isLoadingSlots = true;
  _bookingMessage = null;
});

try {
  final appProvider = Provider.of<AppProvider>(context, listen: false);
  final selectedProfile = appProvider.selectedProfile;

  if (selectedProfile == null) {
    setState(() {
      _bookingMessage = 'Nessun profilo selezionato. Impossibile prenotare.';
    });
    return;
  }

  // Estrai inizio e fine dall'intervallo di tempo selezionato
  final timeParts = _selectedTimeSlot!.split(' - ');
  final inizio = timeParts[0];
  final fine = timeParts[1];

  final success = await appProvider.bookAppointment(
    ambulatorioId: _selectedAmbulatorioId!,
    numero: _selectedAmbulatorioNumber!,
    data: _selectedDate!.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
    inizio: inizio,
    fine: fine,
    telefono: selectedProfile.phoneNumber,
    email: selectedProfile.email, // L'email è ora un campo del profilo
  );

  if (success) {
    setState(() {
      _bookingMessage = 'Prenotazione effettuata con successo!';
      // Resetta i campi o ricarica gli slot
      _selectedTimeSlot = null;
      _fetchAppointmentSlots(); // Ricarica gli slot per mostrare la nuova disponibilità
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prenotazione confermata!')),
    );
  } else {
    setState(() {
      _bookingMessage = 'Errore durante la prenotazione. Riprova.';
    });
  }
} catch (e) {
  setState(() {
    _bookingMessage = 'Errore: ${e.toString()}';
  });
} finally {
  setState(() {
    _isLoadingSlots = false;
  });
}
```

}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Prenota Visita'),
),
drawer: const MainDrawer(), // MainDrawer risolto qui
body: SingleChildScrollView(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: \<Widget\>[
const Text('Seleziona Ambulatorio:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// Dropdown o lista di ambulatori. Per ora usiamo un placeholder.
// In una vera app, questo verrebbe popolato da dati fetched dal backend.
DropdownButton\<int\>(
value: \_selectedAmbulatorioId,
hint: const Text('Seleziona Ambulatorio'),
items: const [
DropdownMenuItem(value: 1, child: Text('Ambulatorio 1 (101)')),
DropdownMenuItem(value: 2, child: Text('Ambulatorio 2 (102)')),
],
onChanged: (int? newValue) {
setState(() {
\_selectedAmbulatorioId = newValue;
// Logica per settare \_selectedAmbulatorioNumber in base all'ID
if (newValue == 1) \_selectedAmbulatorioNumber = 101;
if (newValue == 2) \_selectedAmbulatorioNumber = 102;
\_fetchAppointmentSlots(); // Ricarica slot quando cambia ambulatorio
});
},
),
const SizedBox(height: 20),
const Text('Seleziona Data:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
ElevatedButton(
onPressed: () =\> \_selectDate(context),
child: Text(
\_selectedDate == null
? 'Seleziona una data'
: 'Data selezionata: ${\_selectedDate\!.toLocal().toString().split(' ')[0]}',
),
),
const SizedBox(height: 20),
\_isLoadingSlots
? const Center(child: CircularProgressIndicator())
: \_selectedDate == null || \_availableSlots.isEmpty
? const Text('Nessun slot disponibile per la data o l'ambulatorio selezionati.')
: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('Seleziona Fascia Oraria:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
Wrap(
spacing: 8.0,
runSpacing: 4.0,
children: \_availableSlots.map((slot) {
// Assicurati che AppointmentSlot abbia 'inizio' e 'fine'
final timeRange = '${slot.inizio} - ${slot.fine}';
return ChoiceChip(
label: Text(timeRange),
selected: \_selectedTimeSlot == timeRange,
onSelected: (bool selected) {
setState(() {
\_selectedTimeSlot = selected ? timeRange : null;
});
},
);
}).toList(),
),
],
),
const SizedBox(height: 20),
Center(
child: ElevatedButton(
onPressed: \_bookAppointment,
style: ElevatedButton.styleFrom(
backgroundColor: Theme.of(context).primaryColor,
padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
),
child: const Text(
'Conferma Prenotazione',
style: TextStyle(fontSize: 18, color: Colors.white),
),
),
),
if (\_bookingMessage \!= null)
Padding(
padding: const EdgeInsets.only(top: 20),
child: Center(
child: Text(
\_bookingMessage\!,
style: TextStyle(
color: \_bookingMessage\!.contains('successo') ? Colors.green : Colors.red,
fontSize: 16,
fontWeight: FontWeight.bold,
),
textAlign: TextAlign.center,
),
),
),
],
),
),
);
}
}
