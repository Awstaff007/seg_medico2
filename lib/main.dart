import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico2/auth/auth_service.dart';
import 'package:seg_medico2/auth/auth_wrapper.dart';
import 'package:seg_medico2/data/database.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fornisce l'istanza del database e del servizio di autenticazione
    // all'intera applicazione tramite Provider.
    return MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (context, db) => db.close(),
        ),
        ProxyProvider<AppDatabase, AuthService>(
          update: (context, db, previous) => AuthService(db),
        ),
      ],
      child: MaterialApp(
        title: 'Assistente Medico',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // AuthWrapper gestirà se mostrare la pagina di Login o la HomePage.
        home: const AuthWrapper(),
      ),
    );
  }
}
