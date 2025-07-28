// lib/auth/auth_service.dart

import 'package:flutter/foundation.dart'; // Per ValueNotifier
import 'package:seg_medico2/data/database.dart';
import 'package:drift/drift.dart' hide Column; // Importa Value
import 'package:crypto/crypto.dart'; // Per hashing delle password
import 'dart:convert'; // Per utf8.encode
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Per salvare token

class AuthService {
  // ValueNotifier per notificare i cambiamenti nell'ID utente corrente
  final ValueNotifier<String?> currentUserIdNotifier = ValueNotifier<String?>(null);
  final _storage = const FlutterSecureStorage();

  // Metodo per hashare la password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Metodo di inizializzazione per caricare l'utente salvato
  Future<void> init(AppDatabase database) async {
    final storedUsername = await _storage.read(key: 'username');
    final storedPassword = await _storage.read(key: 'password');

    if (storedUsername != null && storedPassword != null) {
      final user = await login(database, storedUsername, storedPassword);
      if (user != null) {
        currentUserIdNotifier.value = user.id;
      } else {
        // Credenziali obsolete, pulisci
        await _storage.delete(key: 'username');
        await _storage.delete(key: 'password');
      }
    }
  }

  Future<User?> login(AppDatabase database, String username, String password) async {
    final user = await database.getUser(username);
    if (user != null && user.passwordHash == _hashPassword(password)) {
      currentUserIdNotifier.value = user.id; // Aggiorna il notifier al login
      // Salva le credenziali per il login automatico
      await _storage.write(key: 'username', value: username);
      await _storage.write(key: 'password', value: password);
      return user;
    }
    return null;
  }

  Future<User?> register(AppDatabase database, String username, String password) async {
    // Controlla se l'utente esiste già
    final existingUser = await database.getUser(username);
    if (existingUser != null) {
      throw Exception('Username già in uso.');
    }

    // Crea un nuovo utente
    final hashedPassword = _hashPassword(password);
    // Correzione: UsersCompanion.insert prende String direttamente per i campi obbligatori
    final newUserCompanion = UsersCompanion.insert(
      id: username, // NON Value(username) qui
      username: username, // NON Value(username) qui
      passwordHash: hashedPassword, // NON Value(hashedPassword) qui
    );

    final newUserId = await database.createUser(newUserCompanion);
    // Dopo aver creato l'utente, recuperalo per restituirlo
    return await database.getUser(username);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'password');
    currentUserIdNotifier.value = null; // Resetta l'ID utente al logout
  }
}
