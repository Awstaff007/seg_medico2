import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:segreteria_medica/models/farmaco.dart';
import 'package:segreteria_medica/providers/profile_provider.dart';

class ModificaFarmaciScreen extends StatefulWidget {
  const ModificaFarmaciScreen({super.key});

  @override
  State<ModificaFarmaciScreen> createState() => _ModificaFarmaciScreenState();
}

class _ModificaFarmaciScreenState extends State<ModificaFarmaciScreen> {
  final TextEditingController _nuovoFarmacoController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Chiave per la validazione del form

  @override
  void initState() {
    super.initState();
    // Non è più necessario caricare i farmaci qui, ProfileProvider li gestisce
  }

  // Aggiunge un nuovo farmaco alla lista del profilo attivo
  void _addFarmaco() {
    if (_formKey.currentState!.validate()) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final String farmacoNome = _nuovoFarmacoController.text.trim();

      if (profileProvider.currentProfileFarmaci.any((f) => f.nome.toLowerCase() == farmacoNome.toLowerCase())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Questo farmaco è già nella lista.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
        );
        return;
      }

      profileProvider.addFarmacoToActiveProfile(farmacoNome);
      _nuovoFarmacoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Farmaco "$farmacoNome" aggiunto.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
      );
    }
  }

  // Rimuove un farmaco dalla lista del profilo attivo
  void _removeFarmaco(String farmacoNome) {
    Provider.of<ProfileProvider>(context, listen: false).removeFarmacoFromActiveProfile(farmacoNome);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Farmaco "$farmacoNome" rimosso.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final List<Farmaco> listaFarmaci = profileProvider.currentProfileFarmaci;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica Medicinali'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), // Padding aumentato
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '💊 Lista Farmaci Ripetibili:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            listaFarmaci.isEmpty
                ? Center(
                    child: Text(
                      'Nessun farmaco nella lista. Aggiungine uno!',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontStyle: FontStyle.italic),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    constraints: const BoxConstraints(maxHeight: 300), // Altezza fissa per lo scroll
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: listaFarmaci.length,
                      itemBuilder: (context, index) {
                        final farmaco = listaFarmaci[index];
                        return ListTile(
                          title: Text(farmaco.nome, style: Theme.of(context).textTheme.bodyLarge),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 30),
                            onPressed: () => _removeFarmaco(farmaco.nome),
                            tooltip: 'Rimuovi farmaco',
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        );
                      },
                    ),
                  ),
            const Divider(height: 48, thickness: 2),
            Text(
              'Nuovo Farmaco:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nuovoFarmacoController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Nuovo Farmaco',
                        hintText: 'Es: Paracetamolo 500mg',
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Il nome del farmaco non può essere vuoto.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _addFarmaco,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 60),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.add, size: 30),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Torna indietro
                },
                child: Text('Chiudi', style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}