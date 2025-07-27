// lib/widgets/login_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/profilo.dart'; // Importa Profilo
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/services/api_service.dart'; // Assicurati del percorso corretto
import 'dart:async'; // Importa per usare Timer

class LoginDialog extends StatefulWidget {
  final Profilo profile; // Aggiunto il parametro profile

  const LoginDialog({super.key, required this.profile}); // Richiede il profilo

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final TextEditingController _codFisController = TextEditingController();
  final TextEditingController _cellulareController = TextEditingController();
  final TextEditingController _otpCodeController = TextEditingController();
  final ApiService _apiService = ApiService(); // Usiamo l'ApiService

  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _otpCooldown = 0; // Cooldown per OTP
  Timer? _otpTimer;

  @override
  void initState() {
    super.initState();
    // Pre-popola i campi con i dati del profilo selezionato
    // ATTENZIONE: Il tuo modello Profilo non ha 'codiceFiscale'.
    // Se il codice fiscale è necessario, dovrai aggiungerlo al modello Profilo
    // o chiederlo all'utente. Per ora, lo commento per evitare errori.
    // _codFisController.text = widget.profile.codiceFiscale;
    _cellulareController.text = widget.profile.cellulare;
  }

  @override
  void dispose() {
    _codFisController.dispose();
    _cellulareController.dispose();
    _otpCodeController.dispose();
    _otpTimer?.cancel(); // Cancella il timer se è attivo
    super.dispose();
  }

  void _startOtpCooldown() {
    _otpCooldown = 60; // 60 secondi di cooldown
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCooldown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _otpCooldown--;
        });
      }
    });
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Usa il codice fiscale dal campo di testo, se presente, altrimenti una stringa vuota
    // Se il codice fiscale non è nel Profilo, l'utente dovrà digitarlo o recuperarlo diversamente.
    final success = await _apiService.requestOtp(
      _codFisController.text.isNotEmpty ? _codFisController.text : 'dummy_codFis', // Usa un dummy se non presente
      _cellulareController.text,
    );

    setState(() {
      _isLoading = false;
      if (success) {
        _otpSent = true;
        _startOtpCooldown(); // Avvia il cooldown
      } else {
        _errorMessage = 'Errore nell\'invio dell\'OTP o limite di richieste raggiunto.';
      }
    });
  }

  Future<void> _performLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final success = await appProvider.performLogin(
      _codFisController.text.isNotEmpty ? _codFisController.text : 'dummy_codFis', // Usa un dummy se non presente
      _cellulareController.text,
      _otpCodeController.text,
    );

    setState(() {
      _isLoading = false;
      if (success) {
        Navigator.of(context).pop(); // Chiudi il dialog al successo
      } else {
        _errorMessage = appProvider.errorMessage ?? 'Login fallito. Codice OTP errato o dati non validi.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.profile.nome, style: Theme.of(context).textTheme.headlineSmall),
          Text('Telefono: ${widget.profile.cellulare}', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_otpSent) ...[
              // Se il codice fiscale non è nel Profilo, potresti volerlo chiedere qui
              // Per ora, lo lascio come readOnly basato sul fatto che il cellulare è nel profilo
              TextField(
                controller: _codFisController,
                decoration: const InputDecoration(labelText: 'Codice Fiscale', border: OutlineInputBorder()),
                // readOnly: true, // Commentato: se non è nel profilo, l'utente dovrebbe poterlo inserire
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cellulareController,
                decoration: const InputDecoration(labelText: 'Numero Cellulare', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                readOnly: true, // Non modificabile se il profilo è già selezionato
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _otpCooldown == 0 ? _requestOtp : null, // Disabilita durante il cooldown
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_otpCooldown > 0 ? 'Reinvia OTP in $_otpCooldown s' : 'Richiedi Codice SMS'),
                    ),
            ] else ...[
              const Text('Inserisci codice SMS (6 cifre)', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _otpCodeController,
                decoration: const InputDecoration(
                  labelText: 'Codice OTP',
                  border: OutlineInputBorder(),
                  counterText: '', // Nasconde il contatore della lunghezza
                ),
                keyboardType: TextInputType.number,
                maxLength: 6, // Max length 6 cifre
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 10), // Spaziatura per le cifre
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _performLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Accedi'),
                    ),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Permetti di chiudere il dialog
          },
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}
