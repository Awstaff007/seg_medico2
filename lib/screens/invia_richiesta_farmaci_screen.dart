import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Per FilteringTextInputFormatter
import 'package:provider/provider.dart';
import 'package:segreteria_medica/main.dart';
import 'package:segreteria_medica/models/paziente.dart';
import 'package:segreteria_medica/providers/profile_provider.dart';
import 'package:segreteria_medica/providers/settings_provider.dart';

class InviaRichiestaFarmaciScreen extends StatefulWidget {
  final List<String> farmaciSelezionati;
  final Paziente pazienteAttivo; // Passiamo il paziente attivo

  const InviaRichiestaFarmaciScreen({
    super.key,
    required this.farmaciSelezionati,
    required this.pazienteAttivo,
  });

  @override
  State<InviaRichiestaFarmaciScreen> createState() => _InviaRichiestaFarmaciScreenState();
}

class _InviaRichiestaFarmaciScreenState extends State<InviaRichiestaFarmaciScreen> {
  final TextEditingController _otpCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Chiave per la validazione del form

  bool _isAuthenticated = false;
  bool _otpRequested = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _emailController.text = prefs.getString('saved_email') ?? ''; // Carica email salvata
    _checkAuthenticationStatus();
  }

  // Controlla se l'utente è già autenticato con un token valido
  Future<void> _checkAuthenticationStatus() async {
    setState(() { _isLoading = true; });
    final token = await authRepository.getAuthToken();
    if (token != null) {
      final pazienteInfo = await pazienteRepository.getPazienteInfo(token);
      if (pazienteInfo != null && pazienteInfo.codiceFiscale == widget.pazienteAttivo.codiceFiscale) {
        setState(() {
          _isAuthenticated = true;
          _errorMessage = null;
        });
        _createOrder(); // Se autenticato, prova subito a creare l'ordine
      } else {
        await authRepository.logout();
        setState(() {
          _isAuthenticated = false;
          _errorMessage = "Sessione scaduta o non valida per questo profilo, si prega di autenticarsi.";
        });
      }
    } else {
      setState(() {
        _isAuthenticated = false;
      });
    }
    setState(() { _isLoading = false; });
  }

  // Richiesta OTP (se non autenticato)
  Future<void> _requestOtpForAuth() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final success = await authRepository.richiestaOtp(
      widget.pazienteAttivo.codiceFiscale,
      widget.pazienteAttivo.numeroTelefono,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _otpRequested = true;
        } else {
          _errorMessage = "Richiesta OTP fallita. Verifica il numero e riprova.";
        }
      });
    }
  }

  // Login con OTP (se non autenticato)
  Future<void> _loginWithOtpForAuth() async {
    if (_formKey.currentState!.validate()) { // Valida il campo OTP
      setState(() { _isLoading = true; _errorMessage = null; });

      final token = await authRepository.loginConOtp(
        widget.pazienteAttivo.codiceFiscale,
        widget.pazienteAttivo.numeroTelefono,
        _otpCodeController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (token != null) {
            _isAuthenticated = true;
            _otpRequested = false;
            _errorMessage = null;
            _createOrder(); // Ora autenticato, crea l'ordine
          } else {
            _errorMessage = "Codice OTP errato o login fallito. Riprova.";
          }
        });
      }
    }
  }

  // Fase 1: Creazione dell'ordine farmaci (richiede token)
  Future<void> _createOrder() async {
    if (!_isAuthenticated) {
      setState(() { _errorMessage = "Autenticazione richiesta per creare l'ordine."; });
      return;
    }
    if (widget.pazienteAttivo.numeroTelefono.isEmpty) {
      setState(() { _errorMessage = "Numero di telefono del paziente non disponibile."; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    final token = await authRepository.getAuthToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Token non disponibile. Autenticati di nuovo.";
        _isAuthenticated = false;
      });
      return;
    }

    final String farmaciString = widget.farmaciSelezionati.join(', ');
    final String? id = await pazienteRepository.ordinaFarmaciRipetibili(
      token,
      farmaciString,
      widget.pazienteAttivo.numeroTelefono,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (id != null) {
          _orderId = id;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ordine preliminare creato. ID: $id', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
          );
        } else {
          _errorMessage = "Impossibile creare l'ordine. Verifica la connessione o i dati.";
        }
      });
    }
  }

  // Fase 2: Invio dell'ordine (richiede token e orderId)
  Future<void> _submitOrder() async {
    if (_orderId == null || _emailController.text.isEmpty || widget.pazienteAttivo.numeroTelefono.isEmpty) {
      setState(() { _errorMessage = "Compila tutti i campi richiesti."; });
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    final token = await authRepository.getAuthToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Token non disponibile. Autenticati di nuovo.";
        _isAuthenticated = false;
      });
      return;
    }

    await prefs.setString('saved_email', _emailController.text.trim());

    final success = await pazienteRepository.inviaOrdineFarmaci(
      token,
      _orderId!,
      _emailController.text.trim(),
      widget.pazienteAttivo.numeroTelefono,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Richiesta farmaci inviata con successo!', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
          );
          Navigator.of(context).pop();
        } else {
          _errorMessage = "Errore durante l'invio della richiesta. Riprova.";
        }
      });
    }
  }

  String _getGeneratedMessage(String courtesyPhrase) {
    String doctorName = "Giulio Verdi"; // Placeholder
    String finalCourtesyPhrase = courtesyPhrase.replaceAll('[NomeDottore]', doctorName);

    final String farmaciList = widget.farmaciSelezionati.map((f) => '- $f').join('\n');
    return '$finalCourtesyPhrase\n$farmaciList';
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final String courtesyPhrase = settingsProvider.courtesyPhrase;

    Widget contentWidget; // Widget che verrà visualizzato in base allo stato

    if (_isLoading && _orderId == null && !_isAuthenticated) {
      contentWidget = Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Verifica stato di autenticazione...',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (!_isAuthenticated) {
      contentWidget = Column(
        children: [
          Text(
            'Autenticazione richiesta per inviare l\'ordine.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Stai autenticando il profilo:\n${widget.pazienteAttivo.nome}\nCF: ${widget.pazienteAttivo.codiceFiscale}\nTel: ${widget.pazienteAttivo.numeroTelefono}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          if (!_otpRequested)
            ElevatedButton(
              onPressed: _isLoading ? null : _requestOtpForAuth,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Richiedi OTP per Autenticazione', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
            )
          else
            Column(
              children: [
                TextFormField(
                  controller: _otpCodeController,
                  decoration: const InputDecoration(labelText: 'Codice OTP ricevuto'),
                  keyboardType: TextInputType.number,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci il codice OTP.';
                    }
                    if (value.length != 6) {
                      return 'Il codice OTP deve essere di 6 cifre.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginWithOtpForAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Verifica OTP e Autentica', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _otpRequested = false;
                      _otpCodeController.clear();
                      _errorMessage = null;
                    });
                  },
                  child: Text('Richiedi nuovo OTP', style: Theme.of(context).textTheme.labelLarge),
                ),
              ],
            ),
          const Divider(height: 48, thickness: 2),
        ],
      );
    } else if (_orderId == null) {
      contentWidget = Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Creazione ordine preliminare...',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '📤 Invia Richiesta Farmaci',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            '🔐 Inserisci la tua email per la notifica (opzionale):',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Indirizzo Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),

          Text(
            '💬 Messaggio generato:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(15),
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              child: Text(
                _getGeneratedMessage(courtesyPhrase),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '(Questo testo viene generato dai farmaci selezionati. Non modificabile)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isLoading ? null : _submitOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              minimumSize: const Size(double.infinity, 60),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Invia Richiesta Ora', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invia Richiesta Farmaci'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              contentWidget, // Qui viene inserito il widget determinato dalla logica condizionale
            ],
          ),
        ),
      ),
    );
  }
}