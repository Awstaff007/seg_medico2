// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart'; // Importa il tuo database
import 'package:seg_medico2/auth/auth_service.dart'; // Importa AuthService
import 'package:seg_medico2/appointments_page.dart';
import 'package:seg_medico2/medications_page.dart';
import 'package:seg_medico2/history_page.dart';
import 'package:seg_medico2/settings_page.dart';
import 'package:seg_medico2/theme_notifier.dart'; // Importa ThemeNotifier

class HomePage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const HomePage({super.key, required this.db, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Profile? _userProfile;
  Appointment? _nextAppointment;
  int _medicationReminderDays = 0; // Placeholder per i giorni rimanenti

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNextAppointment();
    _calculateMedicationReminder();
  }

  // Carica il profilo utente dal database
  Future<void> _loadUserProfile() async {
    final profile = await widget.db.getProfileForUser(widget.userId);
    setState(() {
      _userProfile = profile;
    });
  }

  // Carica il prossimo appuntamento
  Future<void> _loadNextAppointment() async {
    // Implementa la logica per ottenere il prossimo appuntamento futuro
    // Esempio:
    final allAppointments = await widget.db.watchAppointmentsForUser(widget.userId).first;
    final now = DateTime.now();
    final nextAppt = allAppointments
        .where((a) => a.appointmentDateTime.isAfter(now) && !a.isCompleted)
        .toList()
        ..sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));
    setState(() {
      _nextAppointment = nextAppt.isNotEmpty ? nextAppt.first : null;
    });
  }

  // Calcola i giorni rimanenti per la ripetizione dei farmaci
  void _calculateMedicationReminder() {
    // Logica placeholder. In un'app reale, calcoleresti questo basandoti sui farmaci.
    setState(() {
      _medicationReminderDays = 12; // Esempio
    });
  }

  // Funzione per annullare la prossima visita
  Future<void> _cancelNextAppointment() async {
    if (_nextAppointment != null) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Annulla Appuntamento'),
          content: Text('Sei sicuro di voler annullare l\'appuntamento "${_nextAppointment!.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sì', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Aggiorna l'appuntamento come completato o eliminalo
        await widget.db.updateAppointment(
          AppointmentsCompanion(
            id: Value(_nextAppointment!.id),
            isCompleted: const Value(true), // O elimina completamente: widget.db.deleteAppointment(_nextAppointment!.id);
          ),
        );
        // Aggiungi un'entrata nella cronologia
        await widget.db.addHistoryEntry(
          HistoryEntriesCompanion(
            userId: Value(widget.userId),
            timestamp: Value(DateTime.now()),
            type: Value('appointment_cancelled'),
            description: Value('Appuntamento annullato: ${_nextAppointment!.title}'),
          ),
        );
        _showMessage('Appuntamento annullato.');
        _loadNextAppointment(); // Ricarica per rimuovere l'appuntamento annullato
      }
    }
  }

  // Funzione per il logout
  void _logout() async {
    final authService = AuthService();
    await authService.logout();
    // AuthWrapper gestirà il reindirizzamento alla LoginPage
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeScale = _userProfile?.homepageFontSizeScale?.toDouble() ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Icona per la dimensione del testo
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: () {
                // Logica per cambiare la dimensione del testo globalmente
                // Potresti navigare alla pagina delle impostazioni o mostrare un dialogo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(db: widget.db, userId: widget.userId),
                  ),
                ).then((_) => _loadUserProfile()); // Ricarica il profilo dopo il ritorno
              },
            ),
            const SizedBox(width: 8),
            // Nome utente e dropdown per selezionare profilo
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.userId, // Assumi che l'ID utente sia il valore corrente
                  icon: const Icon(Icons.arrow_drop_down),
                  style: TextStyle(fontSize: 16 * fontSizeScale, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onPrimary),
                  onChanged: (String? newValue) {
                    // Logica per cambiare profilo (non implementata in questo esempio)
                    _showMessage('Funzionalità cambio profilo non implementata.');
                  },
                  items: <String>[widget.userId] // Mostra solo l'utente corrente per ora
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value), // Mostra l'ID utente come nome del profilo
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Logica per gestire i profili (aggiungi/modifica/imposta default)
              _showMessage('Funzionalità gestione profili non implementata.');
            },
            child: Text('Gestisci profili', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          ),
          TextButton(
            onPressed: _logout,
            child: Text('Esci', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card "Prossima visita"
            if (_nextAppointment != null)
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prossima visita: ${_nextAppointment!.appointmentDateTime.toLocal().toString().split('.')[0]}',
                        style: TextStyle(fontSize: 18 * fontSizeScale, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Luogo: ${_nextAppointment!.location ?? 'Nessuno'}',
                        style: TextStyle(fontSize: 16 * fontSizeScale),
                      ),
                      // Aggiungi note se disponibili
                      if (_nextAppointment!.title.isNotEmpty) // Usiamo il titolo come "note" per ora
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '↪ Note: "${_nextAppointment!.title}"',
                            style: TextStyle(fontSize: 14 * fontSizeScale, fontStyle: FontStyle.italic),
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          onPressed: _cancelNextAppointment,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text('Annulla visita', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Card "Ripetizione farmaci"
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ripetizione farmaci tra [ $_medicationReminderDays ] giorni',
                      style: TextStyle(fontSize: 18 * fontSizeScale, fontWeight: FontWeight.bold),
                    ),
                    // Pulsante per ordinare farmaci (placeholder)
                    ElevatedButton(
                      onPressed: () {
                        _showMessage('Funzionalità ordine farmaci non implementata.');
                      },
                      child: const Text('Ordina farmaci'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(), // Spinge il menu in basso

            // Pulsanti principali (Farmaci, Appuntamenti)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MedicationsPage(db: widget.db, userId: widget.userId)),
                      );
                    },
                    icon: const Icon(Icons.medication),
                    label: const Text('Farmaci'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 18 * fontSizeScale),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AppointmentsPage(db: widget.db, userId: widget.userId)),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Appuntamenti'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 18 * fontSizeScale),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Menu laterale (Drawer) - Questo è un placeholder visivo per la struttura
            // Il Drawer effettivo è collegato allo Scaffold.
            Align(
              alignment: Alignment.bottomRight,
              child: Builder(
                builder: (context) => FloatingActionButton.extended(
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer(); // Apre il Drawer a destra
                  },
                  label: const Text('Menu'),
                  icon: const Icon(Icons.menu),
                ),
              ),
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24 * fontSizeScale,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Utente: ${widget.userId}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 16 * fontSizeScale,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text('Cronologia', style: TextStyle(fontSize: 16 * fontSizeScale)),
              onTap: () {
                Navigator.pop(context); // Chiudi il drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryPage(db: widget.db, userId: widget.userId)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.medication),
              title: Text('Farmaci', style: TextStyle(fontSize: 16 * fontSizeScale)),
              onTap: () {
                Navigator.pop(context); // Chiudi il drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MedicationsPage(db: widget.db, userId: widget.userId)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Appuntamenti', style: TextStyle(fontSize: 16 * fontSizeScale)),
              onTap: () {
                Navigator.pop(context); // Chiudi il drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppointmentsPage(db: widget.db, userId: widget.userId)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('Impostazioni', style: TextStyle(fontSize: 16 * fontSizeScale)),
              onTap: () {
                Navigator.pop(context); // Chiudi il drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage(db: widget.db, userId: widget.userId)),
                );
              },
            ),
            // Aggiungi altre voci di menu se necessario
          ],
        ),
      ),
    );
  }
}
