import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico2/auth/auth_service.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/home_page.dart';
import 'package:seg_medico2/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    // Assicurati che AppDatabase sia il tipo corretto per il tuo database.
    // Se stai usando FirebaseFirestore, il tipo potrebbe essere 'FirebaseFirestore'
    // o un wrapper attorno ad esso. Ho mantenuto 'AppDatabase' come nel tuo codice.
    final db = Provider.of<AppDatabase>(context, listen: false);

    // ValueListenableBuilder ascolta i cambiamenti nell'ID utente
    // e ricostruisce l'interfaccia di conseguenza.
    return ValueListenableBuilder<String?>(
      valueListenable: authService.currentUserIdNotifier,
      builder: (_, userId, __) {
        if (userId == null) {
          // Se non c'è un utente loggato, mostra la pagina di login.
          return const LoginPage();
        } else {
          // Se l'utente è loggato, mostra la HomePage.
          // CORREZIONE: Passa direttamente 'userId' come String, senza 'int.parse()'.
          // La HomePage si aspetta una String per userId.
          return HomePage(db: db, userId: userId);
        }
      },
    );
  }
}
