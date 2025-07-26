import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _fiscalCodeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpRequested = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fiscalCodeController.dispose();
    _phoneNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.requestOtp(_fiscalCodeController.text, _phoneNumberController.text);
      setState(() {
        _otpRequested = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codice OTP inviato!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.login(_fiscalCodeController.text, _phoneNumberController.text, _otpController.text);
      if (mounted) {
        Navigator.of(context).pop(); // Chiude il popup di login
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ACCEDI con ${Provider.of<AppProvider>(context).selectedProfile?.name ?? 'Profilo'}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_otpRequested) ...[
              TextField(
                controller: _fiscalCodeController,
                decoration: const InputDecoration(labelText: 'Codice Fiscale'),
              ),
              TextField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Numero di Telefono'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _requestOtp,
                      child: const Text('RICHIEDI CODICE SMS'),
                    ),
            ] else ...[
              Text('Telefono: ${Provider.of<AppProvider>(context).selectedProfile?.phoneNumber ?? 'N/A'}'),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'Inserisci codice SMS (6 cifre)'),
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (value) {
                  if (value.length == 6) {
                    FocusScope.of(context).unfocus(); // Chiudi la tastiera
                  }
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('ACCEDI'),
                    ),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ANNULLA'),
            ),
          ],
        ),
      ),
    );
  }
}
