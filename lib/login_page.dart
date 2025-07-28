// lib/login_page.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/auth/auth_service.dart'; // Importa il servizio di autenticazione
import 'package:seg_medico2/data/database.dart'; // Importa il database Drift

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AppDatabase _database = AppDatabase();
  bool _isLoading = false;
  String? _errorMessage;

  // Funzione per gestire il login
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci username e password.';
        _isLoading = false;
      });
      return;
    }

    try {
      final authService = AuthService(); // Ottieni l'istanza del servizio di autenticazione
      final success = await authService.login(username, password, _database);

      if (success) {
        // Login riuscito, AuthWrapper dovrebbe reindirizzare automaticamente
        _showMessage('Login effettuato con successo!');
      } else {
        setState(() {
          _errorMessage = 'Username o password non validi.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante il login: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Funzione per gestire la registrazione di un nuovo utente (semplificata)
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci username e password per la registrazione.';
        _isLoading = false;
      });
      return;
    }

    try {
      final existingUser = await _database.getUser(username);
      if (existingUser != null) {
        setState(() {
          _errorMessage = 'Username già esistente. Scegliere un altro username.';
        });
      } else {
        // Crea un nuovo utente nel database locale
        await _database.createUser(UsersCompanion.insert(
          id: username, // Usiamo l'username come ID utente per semplicità qui
          username: username,
          passwordHash: password, // In un'app reale, useresti un hash della password
        ));
        _showMessage('Registrazione effettuata con successo! Ora puoi accedere.');
        // Potresti voler svuotare i campi o reindirizzare al login
        _usernameController.clear();
        _passwordController.clear();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante la registrazione: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accedi o Registrati'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/app_logo.png', // Assicurati di avere un logo nella cartella assets
                height: 120,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Accedi', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _register,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Registrati', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
