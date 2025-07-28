import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:seg_medico2/auth/auth_service.dart';
import 'package:seg_medico2/auth/auth_wrapper.dart';
import 'package:drift/drift.dart'; // per usare Value

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final authService = AuthService(db);

  // Inserisce un utente demo all'avvio se non esiste
  final existingUser = await db.getUser('demo');
  if (existingUser == null) {
    await db.createUser(UsersCompanion(name: Value('demo')));
  }

  // Autenticazione automatica dell'utente demo
  await authService.signIn('demo', '');

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: db),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seg Medico',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
    );
  }
}
