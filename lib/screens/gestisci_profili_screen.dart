import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Per FilteringTextInputFormatter
import 'package:provider/provider.dart';
import 'package:segreteria_medica/models/paziente.dart';
import 'package:segreteria_medica/providers/profile_provider.dart';

class GestisciProfiliScreen extends StatefulWidget {
  const GestisciProfiliScreen({super.key});

  @override
  State<GestisciProfiliScreen> createState() => _GestisciProfiliScreenState();
}

class _GestisciProfiliScreenState extends State<GestisciProfiliScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cfController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Chiave per la validazione del form

  @override
  void initState() {
    super.initState();
    // Pre-compila i campi con i dati del profilo attivo all'apertura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      if (profileProvider.activePaziente != null) {
        _nomeController.text = profileProvider.activePaziente!.nome;
        _cfController.text = profileProvider.activePaziente!.codiceFiscale;
        _phoneController.text = profileProvider.activePaziente!.numeroTelefono;
      }
    });
  }

  // Aggiunge o aggiorna un profilo
  void _addOrUpdateProfile() {
    if (_formKey.currentState!.validate()) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      final newProfile = Paziente(
        nome: _nomeController.text.trim(),
        codiceFiscale: _cfController.text.trim().toUpperCase(),
        numeroTelefono: _phoneController.text.trim(),
        isDefault: false, // Lo stato di default è gestito dal provider
      );

      profileProvider.addOrUpdateProfile(newProfile);
      _clearFields();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profilo ${newProfile.nome} salvato.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
      );
    }
  }

  // Pre-compila i campi di input con i dati del profilo da modificare
  void _editProfile(Paziente paziente) {
    setState(() {
      _nomeController.text = paziente.nome;
      _cfController.text = paziente.codiceFiscale;
      _phoneController.text = paziente.numeroTelefono;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modifica il profilo di ${paziente.nome} nei campi sopra.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
    );
  }

  // Elimina un profilo
  void _deleteProfile(Paziente paziente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conferma Eliminazione', style: Theme.of(context).textTheme.titleLarge),
        content: Text('Sei sicuro di voler eliminare il profilo di ${paziente.nome}?', style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annulla', style: Theme.of(context).textTheme.labelLarge),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProfileProvider>(context, listen: false).deleteProfile(paziente);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profilo ${paziente.nome} eliminato.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
              );
              _clearFields(); // Pulisci i campi se il profilo eliminato era quello attivo
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text('Elimina', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Pulisce i campi di input
  void _clearFields() {
    _nomeController.clear();
    _cfController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Guarda lo stato del ProfileProvider
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestisci Profili'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), // Padding aumentato
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sezione Aggiungi / Modifica Profilo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form( // Usa Form per la validazione
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✏️ Aggiungi / Modifica Profilo',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: 'Nome Completo'),
                        style: Theme.of(context).textTheme.bodyLarge,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Il nome non può essere vuoto.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cfController,
                        decoration: const InputDecoration(labelText: 'Codice Fiscale'),
                        textCapitalization: TextCapitalization.characters, // Tutto maiuscolo
                        keyboardType: TextInputType.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(16), // CF italiano 16 caratteri
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')), // Solo lettere maiuscole e numeri
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Il codice fiscale non può essere vuoto.';
                          }
                          if (value.length != 16) {
                            return 'Il codice fiscale deve essere di 16 caratteri.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Numero di Telefono'),
                        keyboardType: TextInputType.phone,
                        style: Theme.of(context).textTheme.bodyLarge,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10), // Numero italiano 10 cifre (es. 3331234567)
                          FilteringTextInputFormatter.digitsOnly, // Solo numeri
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Il numero di telefono non può essere vuoto.';
                          }
                          if (value.length != 10) {
                            return 'Il numero di telefono deve essere di 10 cifre.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: _addOrUpdateProfile,
                          child: Text('Salva / Aggiungi Profilo', style: Theme.of(context).textTheme.labelLarge),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _clearFields,
                          child: Text('Pulisci Campi', style: Theme.of(context).textTheme.labelLarge),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48), // Spazio aumentato

            // Sezione Profili Salvati
            Text(
              '📂 Profili salvati:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24), // Spazio aumentato
            profileProvider.savedProfili.isEmpty
                ? Center(
                    child: Text(
                      'Nessun profilo salvato. Aggiungine uno!',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: profileProvider.savedProfili.length,
                    itemBuilder: (context, index) {
                      final paziente = profileProvider.savedProfili[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ${paziente.nome} ${paziente.isDefault ? '(✅ Predefinito)' : ''}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text('CF: ${paziente.codiceFiscale}', style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 8),
                              Text('Tel: ${paziente.numeroTelefono}', style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _editProfile(paziente),
                                    child: Text('Modifica', style: Theme.of(context).textTheme.labelLarge),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: paziente.isDefault ? null : () => profileProvider.setActiveProfile(paziente),
                                    child: Text(paziente.isDefault ? 'Predefinito' : 'Imposta', style: Theme.of(context).textTheme.labelLarge),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: () => _deleteProfile(paziente),
                                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                                    child: Text('Elimina', style: Theme.of(context).textTheme.labelLarge),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}