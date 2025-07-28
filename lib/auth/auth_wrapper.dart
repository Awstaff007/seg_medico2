// lib/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:seg_medico2/home_page.dart';
import 'package:seg_medico2/login_page.dart';
import 'package:seg_medico2/auth/auth_service.dart'; // Importa il nuovo AuthService
import 'package:seg_medico2/data/database.dart'; // Importa il tuo database

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Inizializza il database e il servizio di autenticazione.
  // Queste istanze saranno passate ai widget figli.
  final AppDatabase _database = AppDatabase();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Inizializza il servizio di autenticazione per caricare lo stato iniziale
    // dall'archiviazione sicura.
    _authService.init();
  }

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder ascolta i cambiamenti in currentUserIdNotifier
    // e ricostruisce il widget quando l'ID utente cambia (login/logout).
    return ValueListenableBuilder<String?>(
      valueListenable: _authService.currentUserIdNotifier,
      builder: (context, userId, child) {
        if (userId == null) {
          // Se l'ID utente è nullo, l'utente non è loggato, mostra la LoginPage.
          return const LoginPage();
        } else {
          // Se l'ID utente è presente, l'utente è loggato, mostra la HomePage.
          // Passa l'istanza del database e l'ID utente alla HomePage.
          return HomePage(db: _database, userId: userId);
        }
      },
    );
  }
}
