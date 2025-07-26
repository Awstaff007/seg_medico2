import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({Key? key}) : super(key: key);

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  bool _isCodeRequested = false;
  int _cooldown = 60;
  Timer? _timer;
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown = 60;
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_cooldown > 0) {
          setState(() {
            _cooldown--;
          });
        } else {
          _timer?.cancel();
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  void _requestCode(AppProvider appProvider) async {
    setState(() {
      _isCodeRequested = true;
    });
    await appProvider.requestLoginSms();
    if (mounted) {
      if (appProvider.errorMessage == null) {
        _startCooldown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appProvider.errorMessage ?? 'Errore sconosciuto')),
        );
        setState(() {
          _isCodeRequested = false;
        });
      }
    }
  }

  void _login(AppProvider appProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await appProvider.login(_pinController.text);
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appProvider.errorMessage ?? 'Errore durante il login.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final profile = appProvider.currentProfile;

    if (profile == null) {
      return AlertDialog(
        title: const Text('Errore'),
        content: const Text('Nessun profilo selezionato. Aggiungine uno per continuare.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      );
    }

    return AlertDialog(
      title: Center(child: Text(profile.name.toUpperCase())),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Center(child: Text('Telefono: ${profile.phone}')),
            const SizedBox(height: 24),
            if (!_isCodeRequested)
              _buildRequestCodeView(appProvider)
            else
              _buildVerifyCodeView(appProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCodeView(AppProvider appProvider) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: appProvider.isLoading ? null : () => _requestCode(appProvider),
          child: appProvider.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('RICHIEDI CODICE SMS'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULLA'),
        )
      ],
    );
  }

  Widget _buildVerifyCodeView(AppProvider appProvider) {
    final defaultPinTheme = PinTheme(
      width: 40,
      height: 45,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text('Inserisci codice SMS (6 cifre)'),
          const SizedBox(height: 16),
          Pinput(
            length: 6,
            controller: _pinController,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyDecorationWith(
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            validator: (s) {
              return s?.length == 6 ? null : 'Il codice deve essere di 6 cifre';
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: appProvider.isLoading ? null : () => _login(appProvider),
            child: appProvider.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('ACCEDI'),
          ),
          TextButton(
            onPressed: _cooldown > 0 ? null : () => _requestCode(appProvider),
            child: Text(_cooldown > 0 ? 'Reinvia tra $_cooldown s' : 'Reinvia codice'),
          ),
           TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULLA'),
          )
        ],
      ),
    );
  }
}
