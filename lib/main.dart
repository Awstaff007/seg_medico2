// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/screens/home_screen.dart'; // Importa la tua Home
import 'package:seg_medico/screens/settings_screen.dart'; // Importa le Impostazioni
import 'package:seg_medico/screens/appointments_screen.dart'; // Importa Appuntamenti (ora nel suo file)
import 'package:seg_medico/screens/drugs_screen.dart'; // Importa Farmaci (ora nel suo file)
import 'package:seg_medico/screens/history_screen.dart'; // Importa Cronologia (ora nel suo file)


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return MaterialApp(
      title: 'Segreteria Medica',
      debugShowCheckedModeBanner: false,
      theme: appProvider.lightThemeData, // Usa il getter per il tema chiaro
      darkTheme: appProvider.darkThemeData, // Usa il getter per il tema scuro
      themeMode: appProvider.themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: appProvider.textScaleFactor,
          ),
          child: child!,
        );
      },
      home: const HomeScreen(), // La tua Home principale
      routes: {
        '/farmaci': (context) => const DrugsScreen(),
        '/appuntamenti': (context) => const AppointmentsScreen(),
        '/cronologia': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
        // Aggiungi qui altre rotte se necessario
      },
    );
  }
}
