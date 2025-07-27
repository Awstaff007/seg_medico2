import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/models/profilo.dart'; // Assicurati che il percorso sia corretto

class ProfileSelectionDialog extends StatelessWidget {
  const ProfileSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final Profilo? currentProfile = appProvider.currentProfile;

    return AlertDialog(
      title: const Text('Il tuo Profilo'),
      content: currentProfile == null
          ? const Text('Nessun profilo selezionato o disponibile. Effettua il login.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nome: ${currentProfile.nome}'),
                Text('Cognome: ${currentProfile.cognome}'),
                Text('Cellulare: ${currentProfile.cellulare}'),
                // Aggiungi altri dettagli del profilo se disponibili nel modello Profilo
                const SizedBox(height: 10),
                // Se volessi permettere la selezione tra più profili (es. familiari),
                // qui dovresti avere una ListView.builder con i profili disponibili.
                // Per ora, mostra solo il profilo attuale.
              ],
            ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Chiudi il dialog
          },
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}
