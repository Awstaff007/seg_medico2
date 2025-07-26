import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/profile_selection_dialog.dart';

class ProfileDropdown extends StatelessWidget {
  const ProfileDropdown({Key? key}) : super(key: key);

  void _manageProfiles(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ProfileSelectionDialog(),
    );
  }

  void _logout(BuildContext context) {
    Provider.of<AppProvider>(context, listen: false).logout();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout effettuato con successo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final profiles = appProvider.getProfiles();
    final currentProfile = appProvider.currentProfile;
    final textScaler = appProvider.fontSizeMultiplier;
    final theme = Theme.of(context);
    final onPrimaryColor = theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary;

    if (profiles.isEmpty) {
      return TextButton(
        onPressed: () => _manageProfiles(context),
        child: Text(
          'Aggiungi Profilo',
          style: TextStyle(color: onPrimaryColor),
          textScaler: TextScaler.linear(textScaler),
        ),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentProfile?.id,
        icon: Icon(Icons.arrow_drop_down, color: onPrimaryColor),
        onChanged: (String? newValue) {
          if (newValue != null) {
            if (newValue == 'manage_profiles') {
              _manageProfiles(context);
            } else if (newValue == 'logout') {
              _logout(context);
            } else {
              appProvider.switchProfile(newValue);
            }
          }
        },
        selectedItemBuilder: (BuildContext context) {
          return [
            Center(
              child: Text(
                currentProfile?.name ?? 'Seleziona profilo',
                style: TextStyle(color: onPrimaryColor, fontSize: 18),
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.linear(textScaler),
              ),
            )
          ];
        },
        items: [
          ...profiles.map<DropdownMenuItem<String>>((Profile profile) {
            return DropdownMenuItem<String>(
              value: profile.id,
              child: Text(profile.name, textScaler: TextScaler.linear(textScaler)),
            );
          }).toList(),
          const DropdownMenuItem<String>(
            value: 'manage_profiles',
            child: ListTile(
              leading: Icon(Icons.manage_accounts),
              title: Text('Gestisci Profili'),
            ),
          ),
          if (appProvider.isLoggedIn)
            const DropdownMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Esci'),
              ),
            ),
        ],
      ),
    );
  }
}
