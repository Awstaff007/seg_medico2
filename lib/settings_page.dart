// lib/settings_page.dart

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/theme_notifier.dart'; // Importa ThemeNotifier

class SettingsPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const SettingsPage({super.key, required this.db, required this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AppDatabase _database;
  late final String _currentUserId;
  Profile? _userProfile;

  bool _receiveReminders = true;
  int _reminderTimeMinutesBefore = 30;
  int _recipeAlertDays = 7;
  int _appointmentReminderDaysBefore = 1; // Corretto il nome della variabile
  String _selectedTheme = 'system';
  double _homepageFontSizeScale = 1.0;

  @override
  void initState() {
    super.initState();
    _database = widget.db;
    _currentUserId = widget.userId;
    _loadProfileSettings();
  }

  Future<void> _loadProfileSettings() async {
    final profile = await _database.getProfileForUser(_currentUserId);
    if (profile != null) {
      setState(() {
        _userProfile = profile;
        _receiveReminders = profile.receiveReminders;
        _reminderTimeMinutesBefore = profile.reminderTimeMinutesBefore;
        _recipeAlertDays = profile.recipeAlertDays;
        _appointmentReminderDaysBefore = profile.appointmentReminderDaysBefore;
        _selectedTheme = profile.selectedTheme;
        _homepageFontSizeScale = profile.homepageFontSizeScale.toDouble(); // Assicurati che sia double
      });
    }
  }

  Future<void> _saveSettings() async {
    final updatedProfile = ProfilesCompanion(
      userId: Value(_currentUserId),
      receiveReminders: Value(_receiveReminders),
      reminderTimeMinutesBefore: Value(_reminderTimeMinutesBefore),
      recipeAlertDays: Value(_recipeAlertDays),
      appointmentReminderDaysBefore: Value(_appointmentReminderDaysBefore),
      selectedTheme: Value(_selectedTheme),
      homepageFontSizeScale: Value(_homepageFontSizeScale),
    );

    await _database.updateProfile(updatedProfile);
    _showMessage('Impostazioni salvate con successo!');
    _loadProfileSettings(); // Ricarica per assicurarsi che lo stato sia aggiornato
    // Applica il tema immediatamente
    ThemeMode themeMode;
    switch (_selectedTheme) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }
    // Usa ThemeNotifier per cambiare il tema
    ThemeNotifier.of(context).setThemeMode(themeMode);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Dimensione testo
                  ListTile(
                    title: const Text('Dimensione testo:'),
                    trailing: DropdownButton<double>(
                      value: _homepageFontSizeScale,
                      onChanged: (double? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _homepageFontSizeScale = newValue;
                          });
                        }
                      },
                      items: const <double>[0.8, 1.0, 1.2, 1.5]
                          .map<DropdownMenuItem<double>>((double value) {
                        return DropdownMenuItem<double>(
                          value: value,
                          child: Text('${(value * 100).toInt()}%'),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  // Promemoria Farmaci
                  SwitchListTile(
                    title: const Text('Ricevi promemoria farmaci'),
                    value: _receiveReminders,
                    onChanged: (bool value) {
                      setState(() {
                        _receiveReminders = value;
                      });
                    },
                  ),
                  ListTile(
                    title: const Text('Promemoria farmaci (minuti prima)'),
                    trailing: DropdownButton<int>(
                      value: _reminderTimeMinutesBefore,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _reminderTimeMinutesBefore = newValue;
                          });
                        }
                      },
                      items: const <int>[15, 30, 60, 120]
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value min'),
                        );
                      }).toList(),
                    ),
                  ),
                  ListTile(
                    title: const Text('Avviso ricetta (giorni prima)'),
                    trailing: DropdownButton<int>(
                      value: _recipeAlertDays,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _recipeAlertDays = newValue;
                          });
                        }
                      },
                      items: const <int>[1, 3, 7, 14, 30]
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value giorni'),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  // Promemoria Appuntamenti
                  ListTile(
                    title: const Text('Promemoria appuntamenti (giorni prima)'),
                    trailing: DropdownButton<int>(
                      value: _appointmentReminderDaysBefore,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _appointmentReminderDaysBefore = newValue;
                          });
                        }
                      },
                      items: const <int>[0, 1, 2, 3, 7] // 0 per "il giorno stesso"
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value giorni'),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  // Tema
                  ListTile(
                    title: const Text('Tema:'),
                    trailing: DropdownButton<String>(
                      value: _selectedTheme,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTheme = newValue;
                          });
                        }
                      },
                      items: const <String>['system', 'light', 'dark']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value == 'system' ? 'Sistema' : (value == 'light' ? 'Chiaro' : 'Scuro')),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text('Salva'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          // Annulla le modifiche e torna indietro
                          _loadProfileSettings(); // Ricarica le impostazioni originali
                          Navigator.pop(context);
                        },
                        child: const Text('Annulla'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
