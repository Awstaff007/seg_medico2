// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/services/api_service.dart';
import 'package:seg_medico/services/profile_manager.dart';
import 'package:seg_medico/screens/home_screen.dart';
import 'package:seg_medico/screens/farmaci_screen.dart';
import 'package:seg_medico/screens/appuntamenti_screen.dart';
import 'package:seg_medico/screens/cronologia_screen.dart';
import 'package:seg_medico/screens/settings_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializzazione notifiche locali
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('app_icon'); // Sostituisci 'app_icon' con il nome dell'icona nella cartella drawable
  const DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      // Gestisci la risposta alla notifica qui
      if (notificationResponse.payload != null) { // Corrected: removed backslash before !=
        debugPrint('notification payload: ${notificationResponse.payload}');
      }
    },
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()), // Corrected: removed backslashes, changed (*) to (_)
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Segretario Medico',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
      routes: {
        '/farmaci': (context) => const FarmaciScreen(), // Corrected: removed backslash
        '/appuntamenti': (context) => const AppuntamentiScreen(), // Corrected: removed backslash
        '/cronologia': (context) => const CronologiaScreen(), // Corrected: removed backslash
        '/impostazioni': (context) => const SettingsScreen(), // Corrected: removed backslash
      },
    );
  }
}