import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:segreteria_medica/main.dart';
import 'package:segreteria_medica/models/paziente.dart';
import 'package:segreteria_medica/models/farmaco.dart';
import 'package:segreteria_medica/providers/profile_provider.dart';
import 'package:segreteria_medica/screens/gestisci_profili_screen.dart';
import 'package:segreteria_medica/screens/modifica_farmaci_screen.dart';
import 'package:segreteria_medica/screens/invia_richiesta_farmaci_screen.dart';


class FarmaciTab extends StatefulWidget {
  final Color backgroundColor;

  const FarmaciTab({super.key, required this.backgroundColor});

  @override
  State<FarmaciTab> createState() => _FarmaciTabState();
}

class _FarmaciTabState extends State<FarmaciTab> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _onReturnFromManagement() async {
    // Ricarica tutti i dati del profilo e dei farmaci dopo essere tornato da una schermata di gestione
    Provider.of<ProfileProvider>(context, listen: false).loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final Paziente? activePaziente = profileProvider.activePaziente;
    final List<Farmaco> listaFarmaci = profileProvider.currentProfileFarmaci;

    return Container(
      color: widget.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      '👤 Profilo attivo:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 28),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const GestisciProfiliScreen()),
                            );
                            _onReturnFromManagement();
                          },
                          tooltip: 'Gestisci Profili',
                        ),
                        Expanded(
                          child: Text(
                            activePaziente?.nome ?? 'Nessun Profilo',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 28),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const GestisciProfiliScreen()),
                            );
                            _onReturnFromManagement();
                          },
                          tooltip: 'Gestisci Profili',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📞 Telefono: ${activePaziente?.numeroTelefono ?? ''}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const GestisciProfiliScreen()),
                        );
                        _onReturnFromManagement();
                      },
                      child: Text('Gestisci Profili', style: Theme.of(context).textTheme.labelLarge),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              '💊 Seleziona per ordinare:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(15),
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: listaFarmaci.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun farmaco disponibile. Aggiungine in "Modifica Farmaci".',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: listaFarmaci.length,
                      itemBuilder: (context, index) {
                        final farmaco = listaFarmaci[index];
                        return CheckboxListTile(
                          title: Text(farmaco.nome, style: Theme.of(context).textTheme.bodyLarge),
                          value: farmaco.selezionato,
                          onChanged: (bool? value) {
                            profileProvider.updateFarmacoSelection(farmaco, value ?? false);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () async {
                if (activePaziente == null || activePaziente.codiceFiscale.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Seleziona o aggiungi un profilo attivo prima di ordinare.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
                  );
                  return;
                }

                final List<String> selectedFarmaciNames = listaFarmaci
                    .where((f) => f.selezionato)
                    .map((f) => f.nome)
                    .toList();

                if (selectedFarmaciNames.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Seleziona almeno un farmaco per ordinare.',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => InviaRichiestaFarmaciScreen(
                      farmaciSelezionati: selectedFarmaciNames,
                      pazienteAttivo: activePaziente,
                    ),
                  ),
                );
                profileProvider.currentProfileFarmaci.forEach((f) => f.selezionato = false);
                profileProvider.saveFarmaciForActiveProfile(profileProvider.currentProfileFarmaci); // Chiamata al metodo pubblico
              },
              child: const Text('Ordina Farmaci'),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 2),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.history, size: 28),
                    label: Text('Storico Ordini', style: Theme.of(context).textTheme.labelLarge),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Storico Ordini da implementare.',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.edit, size: 28),
                    label: Text('Modifica Farmaci', style: Theme.of(context).textTheme.labelLarge),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ModificaFarmaciScreen()),
                      );
                      _onReturnFromManagement();
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}