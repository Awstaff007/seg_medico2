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
          // CORREZIONE: Converte l'ID da String a int come richiesto da HomePage.
          return HomePage(db: db, userId: int.parse(userId));
        }
      },
    );
  }
}
