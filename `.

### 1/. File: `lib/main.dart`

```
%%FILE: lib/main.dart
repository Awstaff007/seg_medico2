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
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AppProvider(
            ApiService(),
            ProfileManager(),
          ),
        ),
        // Aggiungi altri provider se presenti
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Segretario Medico',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // O LoginScreen() a seconda del flusso
      routes: {
        '/home': (context) => HomeScreen(),
        '/farmaci': (context) => FarmaciScreen(),
        '/appuntamenti': (context) => AppuntamentiScreen(),
        '/cronologia': (context) => CronologiaScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
