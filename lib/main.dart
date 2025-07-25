// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/services/api\_service.dart';
import 'package:seg\_medico/services/profile\_manager.dart';
import 'package:seg\_medico/screens/home\_screen.dart';
import 'package:seg\_medico/screens/farmaci\_screen.dart';
import 'package:seg\_medico/screens/appuntamenti\_screen.dart';
import 'package:seg\_medico/screens/cronologia\_screen.dart';
import 'package:seg\_medico/screens/settings\_screen.dart';
import 'package:flutter\_local\_notifications/flutter\_local\_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
WidgetsFlutterBinding.ensureInitialized();

// Inizializzazione notifiche locali
const AndroidInitializationSettings initializationSettingsAndroid =
AndroidInitializationSettings('app\_icon'); // Sostituisci 'app\_icon' con il nome dell'icona nella cartella drawable
const DarwinInitializationSettings initializationSettingsDarwin =
DarwinInitializationSettings(
onDidReceiveLocalNotification: onDidReceiveLocalNotification,
);
const InitializationSettings initializationSettings = InitializationSettings(
android: initializationSettingsAndroid,
iOS: initializationSettingsDarwin,
);
await flutterLocalNotificationsPlugin.initialize(
initializationSettings,
onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
);

runApp(
MultiProvider(
providers: [
Provider\<ApiService\>(create: (*) =\> ApiService()),
Provider\<ProfileManager\>(create: (*) =\> ProfileManager()),
ChangeNotifierProvider(
create: (context) =\> AppProvider(
context.read\<ApiService\>(),
context.read\<ProfileManager\>(),
),
),
],
child: const MyApp(),
),
);
}

// Callback per notifiche iOS in foreground (deprecated, ma utile per compatibilità)
void onDidReceiveLocalNotification(
int id, String? title, String? body, String? payload) async {
// display a dialog with the notification details, tap ok to go to another page
// showDialog(
//   context: navigatorKey.currentState\!.overlay\!.context, // Requires a NavigatorKey
//   builder: (BuildContext context) =\> CupertinoAlertDialog(
//     title: Text(title ?? ''),
//     content: Text(body ?? ''),
//     actions: [
//       CupertinoDialogAction(
//         isDefaultAction: true,
//         child: const Text('Ok'),
//         onPressed: () async {
//           Navigator.of(context, rootNavigator: true).pop();
//           // await Navigator.push(
//           //   context,
//           //   MaterialPageRoute(builder: (context) =\> SecondScreen(payload)),
//           // );
//         },
//       )
//     ],
//   ),
// );
}

// Callback per la risposta alla notifica (quando l'utente interagisce con essa)
void onDidReceiveNotificationResponse(
NotificationResponse notificationResponse) async {
final String? payload = notificationResponse.payload;
if (notificationResponse.payload \!= null) {
debugPrint('notification payload: $payload');
}
// Qui puoi gestire la navigazione o altre azioni in base al payload
// Esempio: Navigator.push(context, MaterialPageRoute(builder: (context) =\> SomePage(payload: payload)));
}

class MyApp extends StatelessWidget {
const MyApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Segreteria Medico',
theme: ThemeData(
primarySwatch: Colors.blue,
visualDensity: VisualDensity.adaptivePlatformDensity,
fontFamily: 'Inter', // Imposta il font Inter come predefinito
),
home: const HomeScreen(),
routes: {
'/farmaci': (context) =\> const FarmaciScreen(),
'/appuntamenti': (context) =\> const AppuntamentiScreen(),
'/cronologia': (context) =\> const CronologiaScreen(),
'/impostazioni': (context) =\> const SettingsScreen(),
},
);
}
}