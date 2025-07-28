import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico2/auth/auth_service.dart';
import 'package:seg_medico2/auth/auth_wrapper.dart';
import 'package:seg_medico2/data/database.dart'; // Assicurati che il percorso sia corretto
import 'package:seg_medico2/appointments_page.dart'; // Importa la pagina Appuntamenti
import 'package:seg_medico2/medications_page.dart';   // Importa la pagina Farmaci
import 'package:seg_medico2/home_page.dart';         // Importa la HomePage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider per AppDatabase - deve essere prima di AuthService
        Provider<AppDatabase>(
          create: (_) => AppDatabase(), // Inizializza la tua istanza di database qui
          dispose: (context, db) => db.close(), // Chiudi il database quando non è più necessario
        ),
        // Provider per AuthService - ora riceve l'istanza di AppDatabase
        Provider<AuthService>(
          create: (context) => AuthService(Provider.of<AppDatabase>(context, listen: false)),
        ),
        // Aggiungi altri provider se ne hai (es. ThemeNotifier)
      ],
      child: MaterialApp(
        title: 'Segretario Medico',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Inter',
        ),
        home: const AuthWrapper(),
        routes: {
          '/appuntamenti': (context) => const AppointmentsPage(),
          '/farmaci': (context) => const MedicationsPage(),
          // Aggiungi qui le rotte per le altre tue pagine
          // '/settings': (context) => const SettingsPage(),
          // '/history': (context) => const HistoryPage(),
          // '/edit_appointment': (context) => const EditAppointmentPage(),
          // '/edit_medication': (context) => const EditMedicationPage(),
        },
      ),
    );
  }
}
