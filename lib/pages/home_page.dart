// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/profile_selection_dialog.dart'; // Importa il dialogo

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            return Text('Segreteria Medica - ${appProvider.currentProfile?.name ?? "Nessun Profilo"}');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return ProfileSelectionDialog(
                    onProfileSelected: (profile) {
                      Provider.of<AppProvider>(context, listen: false).setCurrentProfile(profile);
                      Navigator.of(dialogContext).pop();
                    },
                    onCreateNewProfile: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.pushNamed(context, '/addProfile');
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            if (appProvider.currentProfile == null) {
              return const Text(
                'Seleziona o crea un profilo per iniziare.',
                textAlign: TextAlign.center,
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Benvenuto, ${appProvider.currentProfile!.name}!',
                  style: TextStyle(fontSize: 24 * appProvider.textSize),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funzionalità di gestione appuntamenti in sviluppo!')),
                    );
                  },
                  child: const Text('Gestisci Appuntamenti'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funzionalità di gestione farmaci in sviluppo!')),
                    );
                  },
                  child: const Text('Gestisci Farmaci'),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addProfile');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
