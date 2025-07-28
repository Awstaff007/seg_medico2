import 'package:flutter/foundation.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:drift/drift.dart'; // per usare Value

class AuthService extends ChangeNotifier {
  final AppDatabase database;
  final ValueNotifier<String?> currentUserIdNotifier = ValueNotifier(null);

  AuthService(this.database);

  String? get currentUserId => currentUserIdNotifier.value;

  Future<User?> signIn(String username, String password) async {
    final user = await database.getUser(username);
    if (user != null) {
      currentUserIdNotifier.value = user.id.toString();
      notifyListeners(); // notifico i consumer (es. AuthWrapper)
      return user;
    } else {
      return null;
    }
  }

  Future<void> signOut() async {
    currentUserIdNotifier.value = null;
    notifyListeners(); // notifico che non c'è più utente
  }

  Future<User?> createUser(String username, String password) async {
    final existingUser = await database.getUser(username);
    if (existingUser != null) {
      return null;
    }

    final newUserCompanion = UsersCompanion(
      name: Value(username),
      // Se aggiungi password nel database: password: Value(password),
    );

    final newUserId = await database.createUser(newUserCompanion);
    if (newUserId > 0) {
      final newUser = await database.getUser(username);
      if (newUser != null) {
        currentUserIdNotifier.value = newUser.id.toString();
        notifyListeners(); // notifico accesso del nuovo utente
        return newUser;
      }
    }
    return null;
  }
}
