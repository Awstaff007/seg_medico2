import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/login_dialog.dart';
import 'package:seg_medico/widgets/profile_selection_dialog.dart';


class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

  void _showLoginPrompt(BuildContext context) {
    Navigator.pop(context); // Chiude il drawer prima
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Devi effettuare l\'accesso per vedere questa sezione.'),
        action: SnackBarAction(
          label: 'ACCEDI',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const LoginDialog(),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final textScaler = appProvider.fontSizeMultiplier;
    final profile = appProvider.currentProfile;

    return Drawer(
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              profile?.name ?? 'Nessun profilo',
              style: TextStyle(fontSize: 16 * textScaler, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              profile?.codFis ?? 'Seleziona un profilo',
              style: TextStyle(fontSize: 14 * textScaler),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              child: Text(
                profile?.name.substring(0, 1).toUpperCase() ?? 'P',
                style: TextStyle(fontSize: 40.0 * textScaler, color: Theme.of(context).primaryColor),
              ),
            ),
            otherAccountsPictures: [
              IconButton(
                icon: const Icon(Icons.manage_accounts, color: Colors.white),
                tooltip: 'Gestisci Profili',
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(context: context, builder: (_) => const ProfileSelectionDialog());
                },
              )
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  text: 'Home',
                  route: '/home',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.history,
                  text: 'Cronologia',
                  route: '/cronologia',
                  requiresLogin: true,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.medical_services,
                  text: 'Farmaci',
                  route: '/farmaci',
                  requiresLogin: true,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.calendar_today,
                  text: 'Appuntamenti',
                  route: '/appuntamenti',
                  requiresLogin: true,
                ),
                 const Divider(),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  text: 'Impostazioni',
                  route: '/settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required String route,
    bool requiresLogin = false,
  }) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final textScaler = appProvider.fontSizeMultiplier;
    final isEnabled = !requiresLogin || appProvider.isLoggedIn;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return ListTile(
      leading: Icon(icon, color: isEnabled ? null : Colors.grey),
      title: Text(text, textScaler: TextScaler.linear(textScaler)),
      enabled: isEnabled,
      selected: currentRoute == route,
      onTap: () {
        if (isEnabled) {
           Navigator.pop(context); // Chiude il drawer
           if(currentRoute != route) {
             Navigator.pushNamed(context, route);
           }
        } else {
          _showLoginPrompt(context);
        }
      },
    );
  }
}
