// lib/screens/home\_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:seg\_medico/models/models.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/widgets/login\_dialog.dart';
import 'package:seg\_medico/widgets/profile\_management\_dialog.dart';
import 'package:seg\_medico/widgets/custom\_snackbar.dart';

class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State\<HomeScreen\> createState() =\> \_HomeScreenState();
}

class \_HomeScreenState extends State\<HomeScreen\> {
final GlobalKey\<ScaffoldState\> \_scaffoldKey = GlobalKey\<ScaffoldState\>();

@override
void initState() {
super.initState();
WidgetsBinding.instance.addPostFrameCallback((\_) {
Provider.of\<AppProvider\>(context, listen: false).checkLoginStatus();
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
key: \_scaffoldKey,
appBar: AppBar(
title: Consumer\<AppProvider\>(
builder: (context, appProvider, child) {
return DropdownButtonHideUnderline(
child: DropdownButton\<Profile\>(
value: appProvider.selectedProfile,
hint: const Text('Seleziona profilo'),
onChanged: (Profile? newProfile) {
appProvider.selectProfile(newProfile);
},
items: appProvider.profiles.map((Profile profile) {
return DropdownMenuItem\<Profile\>(
value: profile,
child: Text(profile.name),
);
}).toList(),
),
);
},
),
actions: [
IconButton(
icon: const Icon(Icons.text\_fields), // Icona tT per dimensione caratteri
onPressed: () {
// TODO: Implementare cambio dimensione caratteri globalmente
CustomSnackBar.show(context, 'Funzionalità cambio dimensione caratteri non implementata.');
},
),
ElevatedButton(
onPressed: () {
showDialog(
context: context,
builder: (context) =\> ProfileManagementDialog(
onProfileSelected: (profile) {
Provider.of\<AppProvider\>(context, listen: false).selectProfile(profile);
},
),
);
},
child: const Text('Gestisci profili'),
),
Consumer\<AppProvider\>(
builder: (context, appProvider, child) {
return appProvider.isLoggedIn
? ElevatedButton(
onPressed: () async {
await appProvider.logout();
CustomSnackBar.show(context, 'Logout effettuato.');
},
child: const Text('Esci'),
)
: const SizedBox.shrink(); // Nasconde il pulsante se non loggato
},
),
],
),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Consumer\<AppProvider\>(
builder: (context, appProvider, child) {
final isLoggedIn = appProvider.isLoggedIn;
final userInfo = appProvider.userInfo;
final upcomingAppointment = appProvider.upcomingAppointment;

```
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (upcomingAppointment != null)
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prossima visita: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse('${upcomingAppointment.data} ${upcomingAppointment.inizio}'))}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '↪ Note: "Chiedere dosaggio nuovo farmaco"', // Placeholder for notes
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Conferma annullamento'),
                                content: const Text('Sei sicuro di voler annullare questo appuntamento?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Sì'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && appProvider.selectedProfile != null) {
                              final success = await appProvider.cancelAppointment(
                                upcomingAppointment.id,
                                appProvider.selectedProfile!.phoneNumber,
                              );
                              if (success) {
                                CustomSnackBar.show(context, 'Appuntamento annullato con successo!');
                              } else {
                                CustomSnackBar.show(context, 'Errore durante l\'annullamento dell\'appuntamento.', isError: true);
                              }
                            }
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Annulla visita'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Ripetizione farmaci tra [ 12 ] giorni', // Placeholder for farmaci repetition
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 40),
            if (!isLoggedIn)
              Center(
                child: ElevatedButton(
                  onPressed: appProvider.selectedProfile != null
                      ? () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => LoginDialog(
                              profile: appProvider.selectedProfile!,
                            ),
                          ).then((_) {
                            // After dialog closes, check login status again
                            appProvider.checkLoginStatus();
                          });
                        }
                      : null, // Disabilita il pulsante se nessun profilo è selezionato
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: Text(
                    appProvider.selectedProfile != null
                        ? 'ACCEDI a ${appProvider.selectedProfile!.name}'
                        : 'Seleziona un profilo per accedere',
                  ),
                ),
              ),
            if (isLoggedIn)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/farmaci');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Farmaci'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/appuntamenti');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Appuntamenti'),
                    ),
                  ),
                ],
              ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String value) {
                  if (!isLoggedIn) {
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
                      Navigator.pushNamed(context, '/appuntamenti');
                      break;
                    case 'impostazioni':
                      Navigator.pushNamed(context, '/impostazioni');
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'cronologia',
                    enabled: isLoggedIn,
                    child: Text(isLoggedIn ? 'Cronologia' : '⦿ Cronologia (dis.)'),
                  ),
                  PopupMenuItem<String>(
                    value: 'farmaci',
                    enabled: isLoggedIn,
                    child: Text(isLoggedIn ? 'Farmaci' : '⦿ Farmaci (dis.)'),
                  ),
                  PopupMenuItem<String>(
                    value: 'appuntamenti',
                    enabled: isLoggedIn,
                    child: Text(isLoggedIn ? 'Appuntamenti' : '⦿ Appuntamenti (dis.)'),
                  ),
                  PopupMenuItem<String>(
                    value: 'impostazioni',
                    enabled: isLoggedIn,
                    child: Text(isLoggedIn ? 'Impostazioni' : '⦿ Impostazioni (dis.)'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  ),
);
```

}
}