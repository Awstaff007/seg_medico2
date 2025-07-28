// lib/login_page.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart'; // Importa AppDatabase, User, UsersCompanion
import 'package:seg_medico2/auth/auth_service.dart';
import 'package:seg_medico2/home_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/drift.dart' hide Column; // Importa Value

class LoginPage extends StatefulWidget {
  final AppDatabase db;

  const LoginPage({super.key, required this.db});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  bool _isLogin = true; // true per login, false per registrazione
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    setState(() {
      _isLoading = true;
    });
    final storedUsername = await _storage.read(key: 'username');
    final storedPassword = await _storage.read(key: 'password');

    if (storedUsername != null && storedPassword != null) {
      final user = await _authService.login(widget.db, storedUsername, storedPassword);
      if (user != null) {
        _navigateToHomePage(user.id);
      } else {
        // Se il login automatico fallisce, rimuovi le credenziali obsolete
        await _storage.delete(key: 'username');
        await _storage.delete(key: 'password');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final username = _usernameController.text;
      final password = _passwordController.text;

      User? user;
      String? errorMessage;

      if (_isLogin) {
        user = await _authService.login(widget.db, username, password);
        if (user == null) {
          errorMessage = 'Credenziali non valide.';
        }
      } else {
        // Registrazione
        try {
          user = await _authService.register(widget.db, username, password);
          if (user == null) {
            errorMessage = 'Errore durante la registrazione.';
          }
        } catch (e) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        // Salva le credenziali per il login automatico
        await _storage.write(key: 'username', value: username);
        await _storage.write(key: 'password', value: password);
        _navigateToHomePage(user.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Errore sconosciuto.')),
        );
      }
    }
  }

  void _navigateToHomePage(String userId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(db: widget.db, userId: userId)),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Registrazione'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci un username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci una password';
                        }
                        if (value.length < 6) {
                          return 'La password deve essere di almeno 6 caratteri';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(_isLogin ? 'Accedi' : 'Registrati'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _usernameController.clear();
                          _passwordController.clear();
                        });
                      },
                      child: Text(_isLogin
                          ? 'Non hai un account? Registrati'
                          : 'Hai già un account? Accedi'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
