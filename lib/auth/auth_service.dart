import 'package:flutter/foundation.dart';
import 'package:seg_medico2/data/database.dart';
// CORREZIONE: Aggiunto import mancante per usare 'Value'
import 'package:drift/drift.dart';

class AuthService {
  final AppDatabase database;
  final ValueNotifier<String?> currentUserIdNotifier = ValueNotifier(null);

  // CORREZIONE: Il costruttore ora accetta il database
  AuthService(this.database);

  String? get currentUserId => currentUserIdNotifier.value;

  Future<User?> signIn(String username, String password) async {
    final user = await database.getUser(username);
    if (user != null) {
      currentUserIdNotifier.value = user.id.toString();
      return user;
    } else {
      return null;
    }
  }

  Future<void> signOut() async {
    currentUserIdNotifier.value = null;
  }

  Future<User?> createUser(String username, String password) async {
    final existingUser = await database.getUser(username);
    if (existingUser != null) {
      return null;
    }

    final newUserCompanion = UsersCompanion(
      // CORREZIONE: 'Value' ora è riconosciuto grazie all'import
      name: Value(username),
    );

    final newUserId = await database.createUser(newUserCompanion);
    if (newUserId > 0) {
      final newUser = await database.getUser(username);
      if (newUser != null) {
        currentUserIdNotifier.value = newUser.id.toString();
        return newUser;
      }
    }
    return null;
  }
}
