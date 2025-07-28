// lib/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/auth/auth_service.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/home_page.dart';
import 'package:seg_medico2/login_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AppDatabase _db;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase(); // Inizializza il database
    _authService = AuthService();
    _authService.init(_db); // Inizializza il servizio di autenticazione con il database
  }

  @override
  void dispose() {
    _db.close(); // Chiudi la connessione al database quando il widget viene eliminato
    _authService.currentUserIdNotifier.dispose(); // Dispone del notifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ascolta i cambiamenti nell'ID utente corrente
    return ValueListenableBuilder<String?>(
      valueListenable: _authService.currentUserIdNotifier,
      builder: (context, userId, child) {
        if (userId == null) {
          // Se l'utente non è loggato, mostra la pagina di login
          return LoginPage(db: _db); // Passa l'istanza del database
        } else {
          // Se l'utente è loggato, mostra la home page
          return HomePage(db: _db, userId: userId); // Passa l'istanza del database e l'ID utente
        }
      },
    );
  }
}
