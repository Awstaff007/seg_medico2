// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Importa intl
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/profile_selection_dialog.dart';
import 'package:seg_medico/screens/farmaci_screen.dart'; // Assicurati sia presente se usi FarmaciScreen
import 'package:seg_medico/screens/login_screen.dart'; // Assicurati sia presente
import 'package:seg_medico/screens/booking_screen.dart'; // Assicurati sia presente

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState(); // Corretto: rimossi backslash e sintassi
}

class _HomeScreenState extends State<HomeScreen> { // Corretto: rimossi backslash
  @override
  void initState() {
    super.initState();
    // Inizializza o carica dati qui se necessario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).checkLoginStatus();
      Provider.of<AppProvider>(context, listen: false).loadProfiles();
    });
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Data non valida';
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return 'N/A';
    try {
      final timeParts = time.split(':');
      if (timeParts.length >= 2) {
        return '${timeParts[0]}:${timeParts[1]}';
      }
      return time;
    } catch (e) {
      return 'Ora non valida';
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Sei sicuro di voler effettuare il logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Conferma'),
              onPressed: () async {
                await Provider.of<AppProvider>(context, listen: false).logout();
                Navigator.of(dialogContext).pop();
                // Naviga alla schermata di login o alla schermata iniziale
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelAppointmentDialog(BuildContext context, Appointment appointment) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selectedProfile = appProvider.selectedProfile;

    if (selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun profilo selezionato per annullare l\'appuntamento.')),
      );
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Annulla Appuntamento'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Sei sicuro di voler annullare l\'appuntamento del ${_formatDate(appointment.data)} alle ${_formatTime(appointment.inizio)}?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Conferma'),
              onPressed: () async {
                if (selectedProfile.phoneNumber != null) {
                  final success = await appProvider.cancelAppointment(
                    appointment.id,
                    selectedProfile.phoneNumber!,
                  );
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Appuntamento annullato con successo!' : 'Errore nell\'annullamento dell\'appuntamento.'),
                    ),
                  );
                } else {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Numero di telefono del profilo non disponibile.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Segretario Medico'),
            actions: [
              if (appProvider.isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _showLogoutDialog(context),
                  tooltip: 'Logout',
                ),
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => ProfileSelectionDialog(),
                  );
                  // Ricarica i profili dopo la chiusura del dialog
                  appProvider.loadProfiles();
                },
                tooltip: 'Gestisci Profili',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display del profilo selezionato
                if (appProvider.selectedProfile != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Profilo Selezionato:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Nome: ${appProvider.selectedProfile!.name}', style: const TextStyle(fontSize: 16)),
                            Text('Codice Fiscale: ${appProvider.selectedProfile!.codFis}', style: const TextStyle(fontSize: 16)),
                            Text('Telefono: ${appProvider.selectedProfile!.phoneNumber ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                            Text('Email: ${appProvider.selectedProfile!.email ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Nessun profilo selezionato. Clicca sull\'icona del profilo per selezionarne uno o aggiungerne uno nuovo.',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),

                if (appProvider.selectedProfile != null) ...[
                  if (appProvider.isLoggedIn) ...[
                    // Informazioni utente loggato
                    if (appProvider.userInfo != null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Informazioni Utente (API):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Nome: ${appProvider.userInfo!.name}', style: const TextStyle(fontSize: 16)),
                              Text('Email: ${appProvider.userInfo!.email ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                              Text('Telefono: ${appProvider.userInfo!.phone ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Prossimo Appuntamento
                    const Text('Prossimo Appuntamento:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (appProvider.upcomingAppointment != null)
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID Appuntamento: ${appProvider.upcomingAppointment!.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Data: ${_formatDate(appProvider.upcomingAppointment!.data)}', style: const TextStyle(fontSize: 16)),
                              Text('Ora: ${_formatTime(appProvider.upcomingAppointment!.inizio)} - ${_formatTime(appProvider.upcomingAppointment!.fine)}', style: const TextStyle(fontSize: 16)),
                              Text('Ambulatorio: ${appProvider.upcomingAppointment!.ambulatorioId}', style: const TextStyle(fontSize: 16)),
                              Text('Numero: ${appProvider.upcomingAppointment!.numero}', style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showCancelAppointmentDialog(context, appProvider.upcomingAppointment!),
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Annulla Appuntamento'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Text('Nessun appuntamento in programma.', style: TextStyle(fontSize: 16)),

                    const SizedBox(height: 20),

                    // Azioni principali
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BookingScreen()),
                              );
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Prenota Visita'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FarmaciScreen()),
                              );
                            },
                            icon: const Icon(Icons.medication),
                            label: const Text('Richiedi Farmaci'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]
                  else
                    // Se il profilo è selezionato ma l'utente non è loggato (cioè non ha il token)
                    Column(
                      children: [
                        const Text(
                          'Devi effettuare l\'accesso per visualizzare i tuoi dati e accedere ai servizi.',
                          style: TextStyle(fontSize: 16, color: Colors.orange),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Accedi Ora'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}