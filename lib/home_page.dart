import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/main.dart'; // Import main.dart to access getCurrentUserId and AppDatabaseExtension
import 'package:seg_medico2/appointments_page.dart'; // Import for navigation
import 'package:seg_medico2/medications_page.dart'; // Import for navigation
import 'package:seg_medico2/history_page.dart'; // Import for navigation
import 'package:seg_medico2/settings_page.dart'; // Import for navigation









class HomePage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const HomePage({super.key, required this.db, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Profile? _userProfile;
  late Stream<List<Appointment>> _appointmentsStream;
  late Stream<List<Medication>> _medicationsStream;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _appointmentsStream = widget.db.watchAppointmentsForUser(widget.userId);
    _medicationsStream = widget.db.watchMedicationsForUser(widget.userId);
  }

  Future<void> _loadProfile() async {
    // Watch for changes in the profile for real-time updates
    widget.db.watchProfileForUser(widget.userId).listen((profile) {
      setState(() {
        _userProfile = profile;
      });
    });
  }

  // Helper to format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.toLocal().day}/${dateTime.toLocal().month} ${dateTime.toLocal().hour}:${dateTime.toLocal().minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Use the granular font size if available, otherwise default to 1.0
    final double fontSizeScale = _userProfile?.granularFontSizeScale ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benvenuto, ${_userProfile?.userId ?? 'Utente'}!',
              style: TextStyle(fontSize: 24 * fontSizeScale, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle(context, 'Prossimi Appuntamenti', fontSizeScale),
            _buildAppointmentsList(fontSizeScale),
            const SizedBox(height: 20),
            _buildSectionTitle(context, 'Farmaci in Scadenza/Da Assumere', fontSizeScale),
            _buildMedicationsList(fontSizeScale),
            const SizedBox(height: 20),
            _buildQuickActions(context, fontSizeScale),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, double fontSizeScale) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20 * fontSizeScale, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAppointmentsList(double fontSizeScale) {
    return StreamBuilder<List<Appointment>>(
      stream: _appointmentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text(
            'Nessun appuntamento in programma.',
            style: TextStyle(fontSize: 16 * fontSizeScale),
          );
        } else {
          final upcomingAppointments = snapshot.data!
              .where((a) => a.appointmentDateTime.isAfter(DateTime.now()))
              .toList();
          upcomingAppointments.sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcomingAppointments.length > 3 ? 3 : upcomingAppointments.length,
            itemBuilder: (context, index) {
              final appointment = upcomingAppointments[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(
                    appointment.title,
                    style: TextStyle(fontSize: 18 * fontSizeScale, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${_formatDateTime(appointment.appointmentDateTime)} - ${appointment.location ?? 'Nessuna località'}',
                    style: TextStyle(fontSize: 14 * fontSizeScale),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentsPage(db: widget.db, userId: widget.userId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildMedicationsList(double fontSizeScale) {
    return StreamBuilder<List<Medication>>(
      stream: _medicationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text(
            'Nessun farmaco registrato o in scadenza.',
            style: TextStyle(fontSize: 16 * fontSizeScale),
          );
        } else {
          final upcomingMedications = snapshot.data!
              .where((m) => m.nextDose != null && m.nextDose!.isAfter(DateTime.now()))
              .toList();
          upcomingMedications.sort((a, b) => a.nextDose!.compareTo(b.nextDose!));

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcomingMedications.length > 3 ? 3 : upcomingMedications.length,
            itemBuilder: (context, index) {
              final medication = upcomingMedications[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(
                    medication.name,
                    style: TextStyle(fontSize: 18 * fontSizeScale, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Dose: ${medication.dosage ?? 'Non specificato'} - Prossima dose: ${_formatDateTime(medication.nextDose!)}',
                    style: TextStyle(fontSize: 14 * fontSizeScale),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicationsPage(db: widget.db, userId: widget.userId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, double fontSizeScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Azioni Rapide', fontSizeScale),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildActionButton(context, 'Aggiungi Farmaco', Icons.medication, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicationsPage(db: widget.db, userId: widget.userId)),
              );
            }),
            _buildActionButton(context, 'Aggiungi Appuntamento', Icons.add_alarm, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppointmentsPage(db: widget.db, userId: widget.userId)),
              );
            }),
            _buildActionButton(context, 'Visualizza Storico', Icons.history, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage(db: widget.db, userId: widget.userId)),
              );
            }),
            _buildActionButton(context, 'Impostazioni', Icons.settings, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(db: widget.db, userId: widget.userId)),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16 * (_userProfile?.homepageFontSizeScale ?? 1.0), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
