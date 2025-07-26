// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dimensione Testo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Consumer<AppProvider>(
                      builder: (context, appProvider, child) {
                        return Column(
                          children: [
                            Slider(
                              value: appProvider.textSize,
                              min: 0.8,
                              max: 1.5,
                              divisions: 7,
                              label: appProvider.textSize.toStringAsFixed(1),
                              onChanged: (newValue) {
                                appProvider.setTextSize(newValue);
                              },
                            ),
                            Text(
                              'Esempio di testo con dimensione attuale',
                              style: TextStyle(fontSize: 16 * appProvider.textSize),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tema Applicazione',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Consumer<AppProvider>(
                      builder: (context, appProvider, child) {
                        return DropdownButtonFormField<ThemeMode>(
                          value: appProvider.themeMode,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('Sistema'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Chiaro'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Scuro'),
                            ),
                          ],
                          onChanged: (ThemeMode? newValue) {
                            if (newValue != null) {
                              appProvider.setThemeMode(newValue);
                            }
                          },
                          selectedItemBuilder: (BuildContext context) {
                            return ThemeMode.values.map((ThemeMode mode) {
                              String text = '';
                              if (mode == ThemeMode.system) text = 'Sistema';
                              if (mode == ThemeMode.light) text = 'Chiaro';
                              if (mode == ThemeMode.dark) text = 'Scuro';
                              return Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color));
                            }).toList();
                          },
                          dropdownColor: Theme.of(context).cardColor,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ripetizione Farmaci',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    DropdownButtonFormField<String>(
                      value: 'Giornaliera',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Giornaliera', child: Text('Giornaliera')),
                        DropdownMenuItem(value: 'Settimanale', child: Text('Settimanale')),
                        DropdownMenuItem(value: 'Mensile', child: Text('Mensile')),
                      ],
                      onChanged: (String? newValue) {
                        // Gestisci il cambiamento del valore
                      },
                      selectedItemBuilder: (BuildContext context) {
                        return ['Giornaliera', 'Settimanale', 'Mensile'].map((String value) {
                          return Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color));
                        }).toList();
                      },
                      dropdownColor: Theme.of(context).cardColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
