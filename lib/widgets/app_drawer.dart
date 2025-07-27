import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/screens/appointments_screen.dart';
import 'package:seg_medico/screens/history_screen.dart';
import 'package:seg_medico/screens/home_screen.dart';
import 'package:seg_medico/screens/medicines_screen.dart';
import 'package:seg_medico/screens/settings_screen.dart';
import '../providers/app_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final isLoggedIn = appProvider.isLoggedIn;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(isLoggedIn ? appProvider.selectedProfile!.nome : "Ospite"),
            accountEmail: Text(isLoggedIn ? appProvider.selectedProfile!.cellulare : "Effettua il login"),
            currentAccountPicture: CircleAvatar(
              child: Text(
                isLoggedIn ? appProvider.selectedProfile!.nome[0] : "O",
                style: const TextStyle(fontSize: 40.0),
              ),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            text: 'Home',
            onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen())),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            text: 'Cronologia',
            isEnabled: isLoggedIn,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.medication,
            text: 'Farmaci',
            isEnabled: isLoggedIn,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicinesScreen())),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today,
            text: 'Appuntamenti',
            isEnabled: isLoggedIn,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppointmentsScreen())),
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            text: 'Impostazioni',
            isEnabled: isLoggedIn,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      enabled: isEnabled,
      onTap: isEnabled ? onTap : () {
        Navigator.of(context).pop(); // Chiudi il drawer
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Devi effettuare l'accesso per usare questa funzione.")),
        );
      },
    );
  }
}
