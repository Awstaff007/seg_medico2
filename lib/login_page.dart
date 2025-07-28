import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico2/auth/auth_service.dart';
import 'package:seg_medico2/data/database.dart';

class LoginPage extends StatefulWidget {
  // CORREZIONE: Il costruttore non ha più bisogno del db
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    // Usa Provider per ottenere il servizio
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.signIn(
      _usernameController.text,
      _passwordController.text,
    );

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenziali non valide')),
      );
    }
    // La navigazione ora è gestita da AuthWrapper
  }

  void _register() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.createUser(
      _usernameController.text,
      _passwordController.text,
    );

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utente già esistente')),
      );
    }
    // La navigazione ora è gestita da AuthWrapper
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Accedi'),
            ),
            TextButton(
              onPressed: _register,
              child: const Text('Registrati'),
            ),
          ],
        ),
      ),
    );
  }
}
