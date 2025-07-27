// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/main_drawer.dart'; // Se hai un drawer globale

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Queste variabili ora rifletteranno lo stato globale gestito da AppProvider
  late ThemeMode _selectedThemeMode;
  late double _selectedTextScaleFactor;

  @override
  void initState() {
    super.initState();
    // Inizializza dallo stato corrente del provider
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _selectedThemeMode = appProvider.themeMode;
    _selectedTextScaleFactor = appProvider.textScaleFactor;
  }

  void _saveSettings() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.setThemeMode(_selectedThemeMode);
    appProvider.setTextScaleFactor(_selectedTextScaleFactor);
    // Qui potresti anche salvare su shared_preferences se lo vuoi persistente al riavvio dell'app
    // (AppProvider dovrebbe occuparsene internamente per la persistenza)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impostazioni salvate!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context); // Listen to changes

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        // Puoi aggiungere qui i pulsanti Gestisci Profili/Esci se vuoi replicare l'AppBar
      ),
      // drawer: const MainDrawer(), // Se usi un drawer
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Dimensione testo
            ListTile(
              title: const Text('Dimensione testo'),
              trailing: DropdownButton<double>(
                value: _selectedTextScaleFactor,
                onChanged: (double? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTextScaleFactor = newValue;
                    });
                  }
                },
                items: const <DropdownMenuItem<double>>[
                  DropdownMenuItem<double>(value: 0.8, child: Text('80%')),
                  DropdownMenuItem<double>(value: 1.0, child: Text('100%')),
                  DropdownMenuItem<double>(value: 1.2, child: Text('120%')),
                  DropdownMenuItem<double>(value: 1.5, child: Text('150%')),
                ],
              ),
            ),
            const Divider(),

            // Notifiche Farmaci (Placeholder)
            SwitchListTile(
              title: const Text('Ripetizione farmaci'),
              subtitle: Text('Ogni [30] giorni'),
              value: true, // Placeholder
              onChanged: (bool value) {
                // Implementa logica per salvare la preferenza
              },
            ),
            const Divider(),

            // Notifiche Appuntamenti (Placeholder)
            SwitchListTile(
              title: const Text('Avviso il giorno prima'),
              value: true, // Placeholder
              onChanged: (bool value) {
                // Implementa logica
              },
            ),
            ListTile(
              title: const Text('Avviso [X] min prima'),
              trailing: DropdownButton<int>(
                value: 30, // Placeholder
                onChanged: (int? newValue) {
                  // Implementa logica
                },
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(value: 30, child: Text('30 min')),
                  DropdownMenuItem<int>(value: 60, child: Text('60 min')),
                  DropdownMenuItem<int>(value: 90, child: Text('90 min')),
                  DropdownMenuItem<int>(value: 120, child: Text('120 min')),
                ],
              ),
            ),
            const Divider(),

            // Permessi Push Notifications (Placeholder, richiede setup nativo)
            const ListTile(
              title: Text('Permessi: Push Notifications'),
              trailing: Icon(Icons.check_circle_outline), // Icona di stato
            ),
            const Divider(),

            // Tema
            ListTile(
              title: const Text('Tema:'),
              trailing: DropdownButton<ThemeMode>(
                value: _selectedThemeMode,
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedThemeMode = newValue;
                    });
                  }
                },
                items: const <DropdownMenuItem<ThemeMode>>[
                  DropdownMenuItem<ThemeMode>(value: ThemeMode.system, child: Text('Sistema')),
                  DropdownMenuItem<ThemeMode>(value: ThemeMode.light, child: Text('Chiaro')),
                  DropdownMenuItem<ThemeMode>(value: ThemeMode.dark, child: Text('Scuro')),
                ],
              ),
            ),
            const Divider(),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Logica per provare notifica (richiede setup nativo)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifica di prova inviata!')),
                    );
                  },
                  child: const Text('PROVA NOTIFICA'),
                ),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('SALVA'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('ANNULLA'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}