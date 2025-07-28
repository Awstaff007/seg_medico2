// lib/main.dart

import 'package:flutter/material.dart'; // Importazione fondamentale per i widget Flutter
import 'package:seg_medico2/auth/auth_wrapper.dart'; // PERCORSO CORRETTO: Importa AuthWrapper dalla sottocartella 'auth'
import 'package:seg_medico2/theme_notifier.dart'; // Importa il ThemeNotifier che abbiamo creato

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; // O il tuo valore predefinito

  // Metodo per impostare la modalità del tema
  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Avvolgi MaterialApp con ThemeNotifier per esporre setThemeMode e _themeMode
    return ThemeNotifier(
      themeMode: _themeMode,
      setThemeMode: setThemeMode,
      child: MaterialApp(
        title: 'Segretario Medico',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        themeMode: _themeMode, // Usa la modalità tema gestita dallo stato
        home: const AuthWrapper(), // Il tuo widget di wrapper per l'autenticazione
      ),
    );
  }
}
