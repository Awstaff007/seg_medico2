// lib/auth/auth_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seg_medico2/data/database.dart'; // Importa il tuo database

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final String _userIdKey = 'current_user_id';

  // Notifier per lo stato dell'utente loggato
  final ValueNotifier<String?> currentUserIdNotifier = ValueNotifier<String?>(null);

  // Inizializza il servizio, caricando l'ID utente da secure storage
  Future<void> init() async {
    final userId = await _storage.read(key: _userIdKey);
    currentUserIdNotifier.value = userId;
  }

  // Metodo per il login
  Future<bool> login(String username, String password, AppDatabase database) async {
    final user = await database.getUser(username);

    if (user != null && user.passwordHash == password) { // In un'app reale, confronta l'hash
      await _storage.write(key: _userIdKey, value: user.id);
      currentUserIdNotifier.value = user.id;
      return true;
    }
    return false;
  }

  // Metodo per il logout
  Future<void> logout() async {
    await _storage.delete(key: _userIdKey);
    currentUserIdNotifier.value = null;
  }

  // Metodo per ottenere l'ID dell'utente corrente
  String? getCurrentUserId() {
    return currentUserIdNotifier.value;
  }
}
