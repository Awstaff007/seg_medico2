// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/main.dart';
import 'package:drift/drift.dart' hide Column; // Import Value for explicit nulls if needed

class SettingsPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const SettingsPage({super.key, required this.db, required this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppDatabase _db;
  late String _currentUserId;
  Profile? _userProfile;

  // Default values for settings
  bool _receiveReminders = true;
  int _reminderTimeMinutesBefore = 30;
  int _recipeAlertDays = 7;
  int _appointmentReminderDaysBefore = 1;
  String _selectedTheme = 'system'; // 'system', 'light', 'dark'

  @override
  void initState() {
    super.initState();
    _db = widget.db;
    _currentUserId = widget.userId;
    _loadProfileSettings();
  }

  Future<void> _loadProfileSettings() async {
    _db.watchProfileForUser(_currentUserId).listen((profile) {
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _receiveReminders = profile.receiveReminders;
          _reminderTimeMinutesBefore = profile.reminderTimeMinutesBefore;
          _recipeAlertDays = profile.recipeAlertDays;
          _appointmentReminderDaysBefore = profile.appointmentReminderDaysBefore;
          _selectedTheme = profile.selectedTheme;
        });
      }
    });
  }

  Future<void> _updateProfileSettings() async {
    final updatedProfile = ProfilesCompanion(
      userId: Value(_currentUserId), // userId is the primary key, so use Value() for updates
      receiveReminders: Value(_receiveReminders),
      reminderTimeMinutesBefore: Value(_reminderTimeMinutesBefore),
      recipeAlertDays: Value(_recipeAlertDays),
      appointmentReminderDaysBefore: Value(_appointmentDaysBefore), // This should be `_appointmentReminderDaysBefore`
      selectedTheme: Value(_selectedTheme),
    );
    await _db.updateProfile(updatedProfile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impostazioni salvate!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fontSizeScale = _userProfile?.granularFontSizeScale ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        centerTitle: true,
      ),
      body: _userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SwitchListTile(
                  title: Text('Ricevi Promemoria', style: TextStyle(fontSize: 18 * fontSizeScale)),
                  value: _receiveReminders,
                  onChanged: (bool value) {
                    setState(() {
                      _receiveReminders = value;
                    });
                    _updateProfileSettings();
                  },
                ),
                ListTile(
                  title: Text('Minuti prima del promemoria (farmaci)', style: TextStyle(fontSize: 18 * fontSizeScale)),
                  trailing: DropdownButton<int>(
                    value: _reminderTimeMinutesBefore,
                    items: <int>[5, 10, 15, 30, 60, 120]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value', style: TextStyle(fontSize: 16 * fontSizeScale)),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _reminderTimeMinutesBefore = newValue;
                        });
                        _updateProfileSettings();
                      }
                    },
                  ),
                ),
                ListTile(
                  title: Text('Giorni avviso scadenza ricetta', style: TextStyle(fontSize: 18 * fontSizeScale)),
                  trailing: DropdownButton<int>(
                    value: _recipeAlertDays,
                    items: <int>[1, 3, 7, 14, 30]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value', style: TextStyle(fontSize: 16 * fontSizeScale)),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _recipeAlertDays = newValue;
                        });
                        _updateProfileSettings();
                      }
                    },
                  ),
                ),
                ListTile(
                  title: Text('Giorni avviso appuntamento', style: TextStyle(fontSize: 18 * fontSizeScale)),
                  trailing: DropdownButton<int>(
                    value: _appointmentReminderDaysBefore,
                    items: <int>[0, 1, 2, 3, 7] // 0 means same day
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value', style: TextStyle(fontSize: 16 * fontSizeScale)),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _appointmentReminderDaysBefore = newValue;
                        });
                        _updateProfileSettings();
                      }
                    },
                  ),
                ),
                ListTile(
                  title: Text('Tema App', style: TextStyle(fontSize: 18 * fontSizeScale)),
                  trailing: DropdownButton<String>(
                    value: _selectedTheme,
                    items: <String>['system', 'light', 'dark']
                        .map<DropdownMenuItem<String>>((String value) {
                      String displayText;
                      switch (value) {
                        case 'system':
                          displayText = 'Sistema';
                          break;
                        case 'light':
                          displayText = 'Chiaro';
                          break;
                        case 'dark':
                          displayText = 'Scuro';
                          break;
                        default:
                          displayText = 'Sistema';
                      }
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(displayText, style: TextStyle(fontSize: 16 * fontSizeScale)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTheme = newValue;
                        });
                        // Apply theme change immediately for visual feedback
                        _applyTheme(newValue);
                        _updateProfileSettings();
                      }
                    },
                  ),
                ),
                Slider(
                  value: fontSizeScale,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: fontSizeScale.toStringAsFixed(1),
                  onChanged: (double value) {
                    setState(() {
                      // We don't save granularFontSizeScale via _updateProfileSettings directly here
                      // since it's handled by a separate update operation.
                      // This ensures the slider updates visually.
                    });
                  },
                  onChangeEnd: (double value) async {
                    // Save granularFontSizeScale only when the user finishes dragging
                    final updatedProfile = ProfilesCompanion(
                      userId: Value(_currentUserId),
                      granularFontSizeScale: Value(value),
                    );
                    await _db.updateProfile(updatedProfile);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scala font aggiornata!')),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Dimensione Testo: ${fontSizeScale.toStringAsFixed(1)}x',
                    style: TextStyle(fontSize: 16 * fontSizeScale),
                  ),
                ),
              ],
            ),
    );
  }

  void _applyTheme(String themeName) {
    ThemeMode themeMode;
    switch (themeName) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        break;
    }
    // Access the MyApp state to change the theme
    MyApp.of(context).setThemeMode(themeMode);
  }
}