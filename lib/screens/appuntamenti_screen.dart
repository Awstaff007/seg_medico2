// lib/screens/appuntamenti_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/custom_snackbar.dart';

class AppuntamentiScreen extends StatefulWidget {
  const AppuntamentiScreen({super.key});

  @override
  State<AppuntamentiScreen> createState() => _AppuntamentiScreenState();
}

class _AppuntamentiScreenState extends State<AppuntamentiScreen> {
  // Changed to Map<DateTime, List<String>>
  Map<DateTime, List<String>> _availableSlots = {};
  List<DateTime> _availableDates = []; // Added to store sorted dates
  bool _isLoadingSlots = false;
  String? _selectedSlotDisplay; // Changed to store the display string
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAvailableSlots();
  }

  Future<void> _fetchAvailableSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _availableSlots = {};
      _availableDates = [];
      _selectedSlotDisplay = null;
    });

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final userInfo = appProvider.userInfo;
    final selectedProfile = appProvider.selectedProfile; // Also need selected profile for ambulatorio

    // Ensure userInfo and ambulatori are available before fetching slots
    if (userInfo != null && userInfo.ambulatori.isNotEmpty) {
      // Assuming ambulatorioId comes from the selected profile or user's primary ambulatorio
      // For simplicity, using the first ambulatorio from UserInfo, adjust if needed
      final ambulatorioId = userInfo.ambulatori.first.id;
      // You might need to determine `numero` based on context, here assuming a default of 1
      final slots = await appProvider.getAppointmentSlots(ambulatorioId, 1);
      setState(() {
        _availableSlots = slots;
        _availableDates = slots.keys.toList()..sort(); // Sort dates
        _isLoadingSlots = false;
      });
    } else {
      setState(() {
        _isLoadingSlots = false;
      });
      CustomSnackBar.show(context, 'Nessun ambulatorio disponibile o informazioni utente/profilo mancanti.', isError: true);
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedSlotDisplay == null) {
      CustomSnackBar.show(context, 'Seleziona uno slot disponibile per prenotare.', isError: true);
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final userInfo = appProvider.userInfo;
    final selectedProfile = appProvider.selectedProfile;

    if (userInfo == null || selectedProfile == null || userInfo.ambulatori.isEmpty) {
      CustomSnackBar.show(context, 'Informazioni utente o profilo non disponibili. Assicurati di aver selezionato un profilo e che l\'utente abbia ambulatori associati.', isError: true);
      return;
    }

    final ambulatorioId = userInfo.ambulatori.first.id; // Using the first ambulatorio
    final parts = _selectedSlotDisplay!.split(' – ');
    final datePart = parts[0];
    final timePart = parts[1];

    final data = DateFormat('dd MMM yyyy', 'it_IT').parse(datePart); // Use Italian locale for parsing
    final formattedDate = DateFormat('yyyy/MM/dd').format(data); // Format to API required format
    final inizio = timePart; // This is already in HH:mm format
    // Calculate 'fine' based on 'inizio', assuming a fixed duration (e.g., 15 minutes)
    final parsedInizio = DateFormat('HH:mm').parse(inizio);
    final fine = DateFormat('HH:mm').format(parsedInizio.add(const Duration(minutes: 15))); // Assuming 15 min duration

    final success = await appProvider.bookAppointment(
      ambulatorioId: ambulatorioId,
      numero: 1, // Booking 1 slot, adjust if API supports multiple
      data: formattedDate,
      inizio: inizio,
      fine: fine,
      telefono: selectedProfile.phoneNumber,
      email: selectedProfile.email, // Use email from profile
    );

    if (success) {
      CustomSnackBar.show(context, 'Appuntamento prenotato con successo!');
      _notesController.clear(); // Clear notes after booking
      _fetchAvailableSlots(); // Refresh slots after booking
      // Optionally navigate back or show a confirmation screen
    } else {
      CustomSnackBar.show(context, 'Errore durante la prenotazione. Riprova.', isError: true);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APPUNTAMENTI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              CustomSnackBar.show(context, 'Funzionalità cambio dimensione caratteri non implementata.');
            },
          ),
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return DropdownButtonHideUnderline(
                child: DropdownButton<Profile>(
                  value: appProvider.selectedProfile,
                  hint: const Text('Seleziona profilo'),
                  onChanged: (Profile? newProfile) {
                    appProvider.selectProfile(newProfile);
                  },
                  items: appProvider.profiles.map((Profile profile) {
                    return DropdownMenuItem<Profile>(
                      value: profile,
                      child: Text(profile.name),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return ElevatedButton(
                onPressed: () async {
                  await appProvider.logout();
                  CustomSnackBar.show(context, 'Logout effettuato.');
                  // Ensure navigating back to the login/initial screen
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('Esci'),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disponibilità via API:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : _availableDates.isEmpty
                    ? const Text('Nessuna disponibilità trovata.')
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _availableDates.length,
                          itemBuilder: (context, dateIndex) {
                            final date = _availableDates[dateIndex];
                            final times = _availableSlots[date]!;
                            final displayDate = DateFormat('dd MMM yyyy', 'it_IT').format(date);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    displayDate,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                ...times.map((time) {
                                  final displayText = '$displayDate – $time';
                                  return RadioListTile<String>(
                                    title: Text(displayText),
                                    value: displayText,
                                    groupValue: _selectedSlotDisplay,
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedSlotDisplay = value;
                                      });
                                    },
                                  );
                                }).toList(),
                                const Divider(), // Separator between dates
                              ],
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 20),
            const Text(
              '✏ Note visita:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Aggiungi note per la visita...',
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedSlotDisplay != null ? _bookAppointment : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('PRENOTA'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to home
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('ANNULLA'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                if (!appProvider.isLoggedIn) {
                  CustomSnackBar.show(context, 'Accedi per accedere al menu.');
                  return;
                }
                switch (value) {
                  case 'cronologia':
                    Navigator.pushNamed(context, '/cronologia');
                    break;
                  case 'farmaci':
                    Navigator.pushNamed(context, '/farmaci');
                    break;
                  case 'appuntamenti':
                  // Already on appuntamenti screen
                    break;
                  case 'impostazioni':
                    Navigator.pushNamed(context, '/impostazioni');
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'cronologia',
                  enabled: Provider.of<AppProvider>(context).isLoggedIn,
                  child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Cronologia' : '⦿ Cronologia (dis.)'),
                ),
                PopupMenuItem<String>(
                  value: 'farmaci',
                  enabled: Provider.of<AppProvider>(context).isLoggedIn,
                  child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Farmaci' : '⦿ Farmaci (dis.)'),
                ),
                PopupMenuItem<String>(
                  value: 'appuntamenti',
                  enabled: Provider.of<AppProvider>(context).isLoggedIn,
                  child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Appuntamenti' : '⦿ Appuntamenti (dis.)'),
                ),
                PopupMenuItem<String>(
                  value: 'impostazioni',
                  enabled: Provider.of<AppProvider>(context).isLoggedIn,
                  child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Impostazioni' : '⦿ Impostazioni (dis.)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}