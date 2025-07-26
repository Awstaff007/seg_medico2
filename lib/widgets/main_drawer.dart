// lib/widgets/main_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/profile_selection_dialog.dart'; // Import the dialog

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Corrected: Removed backslashes and added listen: false for non-listening access
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Segretario Medico',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                // Using Consumer to react to changes in selectedProfile
                Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    if (provider.selectedProfile != null) {
                      return Text(
                        '${provider.selectedProfile!.name} (${provider.selectedProfile!.codFis})', // Uses codFis from Profile
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      );
                    } else {
                      return const Text(
                        'Nessun profilo selezionato',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Gestisci Profili'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Corrected: Directly show the dialog instead of calling a method on AppProvider
              showDialog(
                context: context,
                builder: (context) => const ProfileSelectionDialog(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_hospital),
            title: const Text('Farmaci'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/farmaci');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Appuntamenti'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/appuntamenti');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Cronologia'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/cronologia');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Impostazioni'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/impostazioni');
            },
          ),
        ],
      ),
    );
  }
}