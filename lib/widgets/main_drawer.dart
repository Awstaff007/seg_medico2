// lib/widgets/main_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/login_dialog.dart'; // Per il dialogo di login

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final profile = appProvider.selectedProfile;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    profile?.nome?.substring(0, 1).toUpperCase() ?? 'P',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile?.nome ?? 'Nessun profilo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  profile?.cellulare ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: Text(appProvider.isLoggedIn ? 'Logout' : 'Login'),
            onTap: () {
              Navigator.of(context).pop(); // Chiudi il drawer
              if (appProvider.isLoggedIn) {
                appProvider.logout();
                // refreshAppointments() non è più necessario qui
              } else {
                if (appProvider.selectedProfile != null) {
                  showDialog(
                    context: context,
                    builder: (_) => LoginDialog(
                      profile: appProvider.selectedProfile!, // Passa il profilo
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleziona un profilo prima di fare il login')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Cronologia'),
            onTap: () {
              Navigator.pop(context);
              if (appProvider.isLoggedIn) {
                Navigator.pushNamed(context, '/cronologia');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Accedi per vedere la cronologia completa.')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication),
            title: const Text('Farmaci'),
            onTap: appProvider.isLoggedIn
                ? () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/farmaci');
                  }
                : null, // Disabilita se non loggato
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Appuntamenti'),
            onTap: appProvider.isLoggedIn
                ? () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/appuntamenti');
                  }
                : null, // Disabilita se non loggato
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Impostazioni'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }
}
