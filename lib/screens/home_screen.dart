// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/profilo.dart'; // Assicurati di importare Profilo correttamente
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/login_dialog.dart'; // Per il dialogo di login
import 'package:seg_medico/widgets/profile_selection_dialog.dart'; // Per il dialogo di gestione profili
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // Per il menu FAB
import 'package:intl/intl.dart'; // Per formattare la data

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Trova il prossimo appuntamento valido
        Map<String, dynamic>? nextAppointment;
        if (appProvider.isLoggedIn && appProvider.appointments.isNotEmpty) {
          // Filtra appuntamenti futuri e ordina per data/ora
          final now = DateTime.now();
          final futureAppointments = appProvider.appointments.where((app) {
            final appDateTime = DateTime.parse('${app['date']} ${app['time']}'); // Assumi formato YYYY-MM-DD HH:mm
            return appDateTime.isAfter(now);
          }).toList();
          futureAppointments.sort((a, b) {
            final dateTimeA = DateTime.parse('${a['date']} ${a['time']}');
            final dateTimeB = DateTime.parse('${b['date']} ${b['time']}');
            return dateTimeA.compareTo(dateTimeB);
          });

          if (futureAppointments.isNotEmpty) {
            nextAppointment = futureAppointments.first;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                // Icona tT per dimensione testo
                IconButton(
                  icon: const Icon(Icons.format_size),
                  onPressed: () {
                    final currentScale = appProvider.textScaleFactor;
                    appProvider.setTextScaleFactor(currentScale == 1.0 ? 1.2 : 1.0);
                  },
                ),
                const SizedBox(width: 8),
                // Dropdown per selezione profilo
                Expanded(
                  child: DropdownButton<Profilo>(
                    value: appProvider.selectedProfile,
                    hint: const Text('Seleziona profilo', style: TextStyle(color: Colors.white70)),
                    dropdownColor: Theme.of(context).primaryColor, // Colore sfondo dropdown
                    style: const TextStyle(color: Colors.white, fontSize: 16), // Colore testo elementi
                    iconEnabledColor: Colors.white, // Colore freccia dropdown
                    onChanged: (Profilo? p) {
                      appProvider.selectProfile(p);
                    },
                    items: appProvider.localProfiles.map((Profilo p) { // Correzione: profili -> localProfiles
                      return DropdownMenuItem<Profilo>(
                        value: p,
                        child: Text(p.nome),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                // Pulsante Gestisci profili
                TextButton(
                  onPressed: () {
                    // La gestione profili è offline, quindi non richiede login
                    showDialog(
                      context: context,
                      builder: (context) => ProfileSelectionDialog(),
                    );
                  },
                  child: const Text('Gestisci profili', style: TextStyle(color: Colors.white)),
                ),
                // Pulsante Esci (solo post-login)
                if (appProvider.isLoggedIn)
                  TextButton(
                    onPressed: () {
                      appProvider.logout();
                      // refreshAppointments() non è più necessario qui, la logica è in logout()
                    },
                    child: const Text('Esci', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sezione Prossima visita
                if (nextAppointment != null) // Mostra solo se c'è un prossimo appuntamento
                  Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prossima visita: ${DateFormat('dd MMM yyyy').format(DateTime.parse(nextAppointment['date']))}, ore ${nextAppointment['time']}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '↪ Note: "${nextAppointment['note']}"',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Conferma Annullamento'),
                                    content: const Text('Sei sicuro di voler annullare questa visita?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Sì'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await appProvider.cancelAppointment(nextAppointment!['id']);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(appProvider.errorMessage ?? 'Appuntamento annullato!')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.cancel),
                              label: const Text('Annulla visita'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Sezione Ripetizione farmaci (dinamica)
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ripetizione farmaci ogni:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            DropdownButton<int>(
                              value: appProvider.medicationReminderDays,
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  appProvider.setMedicationReminderDays(newValue);
                                }
                              },
                              items: <int>[30, 60, 90, 120]
                                  .map<DropdownMenuItem<int>>((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value giorni'),
                                );
                              }).toList(),
                            ),
                            Switch(
                              value: appProvider.medicationReminderEnabled,
                              onChanged: (bool value) {
                                appProvider.toggleMedicationReminder(value);
                              },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                        if (appProvider.medicationReminderEnabled)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Avviso attivo: ${appProvider.medicationReminderDays} giorni prima.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Pulsanti ACCEDI / Farmaci / Appuntamenti
                Center(
                  child: appProvider.isLoggedIn
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/farmaci');
                              },
                              icon: const Icon(Icons.medication),
                              label: const Text('Farmaci'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                textStyle: const TextStyle(fontSize: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/appuntamenti');
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Appuntamenti'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                textStyle: const TextStyle(fontSize: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: appProvider.selectedProfile != null
                              ? () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => LoginDialog(
                                      profile: appProvider.selectedProfile!, // Passa il profilo selezionato
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: appProvider.selectedProfile != null ? Theme.of(context).primaryColor : Colors.grey[400],
                            foregroundColor: Colors.white,
                          ),
                          child: Text(appProvider.selectedProfile != null
                              ? 'ACCEDI a ${appProvider.selectedProfile!.nome}'
                              : 'Seleziona un profilo'),
                        ),
                ),
                const Spacer(), // Spinge il menu in basso
              ],
            ),
          ),
          floatingActionButton: SpeedDial(
            icon: Icons.menu,
            activeIcon: Icons.close,
            spacing: 3,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.history),
                label: 'Cronologia',
                onTap: () {
                  if (appProvider.isLoggedIn) {
                    Navigator.pushNamed(context, '/cronologia');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Accedi per vedere la cronologia completa.')),
                    );
                  }
                },
                backgroundColor: appProvider.isLoggedIn ? null : Colors.blueGrey,
                foregroundColor: appProvider.isLoggedIn ? null : Colors.white,
              ),
              SpeedDialChild(
                child: const Icon(Icons.medication),
                label: 'Farmaci',
                onTap: appProvider.isLoggedIn
                    ? () {
                        Navigator.pushNamed(context, '/farmaci');
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accedi per vedere i farmaci.')),
                        );
                      },
                backgroundColor: appProvider.isLoggedIn ? null : Colors.grey,
                foregroundColor: appProvider.isLoggedIn ? null : Colors.white,
              ),
              SpeedDialChild(
                child: const Icon(Icons.calendar_today),
                label: 'Appuntamenti',
                onTap: appProvider.isLoggedIn
                    ? () {
                        Navigator.pushNamed(context, '/appuntamenti');
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accedi per vedere gli appuntamenti.')),
                        );
                      },
                backgroundColor: appProvider.isLoggedIn ? null : Colors.grey,
                foregroundColor: appProvider.isLoggedIn ? null : Colors.white,
              ),
              SpeedDialChild(
                child: const Icon(Icons.settings),
                label: 'Impostazioni',
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                backgroundColor: Theme.of(context).primaryColor, // Sempre disponibile e colorato
                foregroundColor: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }
}
