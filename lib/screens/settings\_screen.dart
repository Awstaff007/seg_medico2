// lib/screens/settings\_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/widgets/custom\_snackbar.dart';
import 'package:flutter\_local\_notifications/flutter\_local\_notifications.dart';
import 'package:seg\_medico/main.dart'; // Importa main.dart per accedere a flutterLocalNotificationsPlugin

class SettingsScreen extends StatefulWidget {
const SettingsScreen({super.key});

@override
State\<SettingsScreen\> createState() =\> \_SettingsScreenState();
}

class \_SettingsScreenState extends State\<SettingsScreen\> {
double \_textSize = 1.0; // Default text size (100%)
bool \_repeatFarmaci = true;
int \_farmaciRepeatDays = 30;
bool \_appointmentDayBefore = true;
bool \_appointmentMinBefore = true;
int \_appointmentMinBeforeValue = 30;
String \_theme = 'Chiaro'; // 'Chiaro' or 'Scuro'

@override
void initState() {
super.initState();
\_loadSettings();
}

Future\<void\> \_loadSettings() async {
// TODO: Load settings from SharedPreferences or similar
// For now, using default values
}

Future\<void\> \_saveSettings() async {
// TODO: Save settings to SharedPreferences or similar
CustomSnackBar.show(context, 'Impostazioni salvate\!');
}

Future\<void\> \_testNotification() async {
const AndroidNotificationDetails androidPlatformChannelSpecifics =
AndroidNotificationDetails(
'your channel id',
'your channel name',
channelDescription: 'your channel description',
importance: Importance.max,
priority: Priority.high,
showWhen: false,
);
const DarwinNotificationDetails darwinPlatformChannelSpecifics =
DarwinNotificationDetails();
const NotificationDetails platformChannelSpecifics = NotificationDetails(
android: androidPlatformChannelSpecifics,
iOS: darwinPlatformChannelSpecifics,
);
await flutterLocalNotificationsPlugin.show(
0,
'Notifica di prova',
'Questa è una notifica di prova dalla tua app.',
platformChannelSpecifics,
payload: 'test\_notification',
);
CustomSnackBar.show(context, 'Notifica di prova inviata\!');
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('IMPOSTAZIONI'),
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
Text('📏 Dimensione testo: ${(\_textSize \* 100).toInt()}%', style: const TextStyle(fontSize: 18)),
Slider(
value: \_textSize,
min: 0.5,
max: 2.0,
divisions: 3, // 50%, 100%, 150%, 200%
label: '${(\_textSize \* 100).toInt()}%',
onChanged: (newValue) {
setState(() {
\_textSize = newValue;
// TODO: Apply global text size change
});
},
),
const SizedBox(height: 20),
Text('🔔 Farmaci:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
Row(
children: [
const Text('Ripetizione ogni '),
SizedBox(
width: 50,
child: TextField(
keyboardType: TextInputType.number,
textAlign: TextAlign.center,
controller: TextEditingController(text: \_farmaciRepeatDays.toString()),
onChanged: (value) {
setState(() {
\_farmaciRepeatDays = int.tryParse(value) ?? 30;
});
},
),
),
const Text(' giorni'),
Switch(
value: \_repeatFarmaci,
onChanged: (newValue) {
setState(() {
\_repeatFarmaci = newValue;
});
},
),
],
),
const SizedBox(height: 20),
Text('🔔 Appuntamenti:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
Row(
children: [
const Text('Avviso il giorno prima'),
const Spacer(),
Switch(
value: \_appointmentDayBefore,
onChanged: (newValue) {
setState(() {
\_appointmentDayBefore = newValue;
});
},
),
],
),
Row(
children: [
const Text('Avviso '),
SizedBox(
width: 50,
child: TextField(
keyboardType: TextInputType.number,
textAlign: TextAlign.center,
controller: TextEditingController(text: \_appointmentMinBeforeValue.toString()),
onChanged: (value) {
setState(() {
\_appointmentMinBeforeValue = int.tryParse(value) ?? 30;
});
},
),
),
const Text(' min prima'),
Switch(
value: \_appointmentMinBefore,
onChanged: (newValue) {
setState(() {
\_appointmentMinBefore = newValue;
});
},
),
],
),
const SizedBox(height: 20),
Text('Permessi:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const Text('◦ Push Notifications'), // Placeholder, actual permission check/request needed
const SizedBox(height: 20),
Text('🎨 Tema:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
Row(
children: [
Radio\<String\>(
value: 'Chiaro',
groupValue: \_theme,
onChanged: (value) {
setState(() {
\_theme = value\!;
// TODO: Apply theme change
});
},
),
const Text('Chiaro'),
Radio\<String\>(
value: 'Scuro',
groupValue: \_theme,
onChanged: (value) {
setState(() {
\_theme = value\!;
// TODO: Apply theme change
});
},
),
const Text('Scuro'),
],
),
const Spacer(),
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
Expanded(
child: ElevatedButton(
onPressed: \_testNotification,
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 15),
textStyle: const TextStyle(fontSize: 18),
),
child: const Text('PROVA NOTIFICA'),
),
),
const SizedBox(width: 20),
Expanded(
child: ElevatedButton(
onPressed: \_saveSettings,
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 15),
textStyle: const TextStyle(fontSize: 18),
),
child: const Text('SALVA'),
),
),
const SizedBox(width: 20),
Expanded(
child: ElevatedButton(
onPressed: () {
Navigator.pop(context); // Go back without saving
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
Navigator.pushNamed(context, '/appuntamenti');
break;
case 'impostazioni':
// Already on impostazioni screen
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