import 'package:flutter/foundation.dart'; // Per ValueNotifier
import 'package:seg_medico2/data/database.dart'; // Per AppDatabase e UsersCompanion
import 'package:drift/drift.dart' as d; // Per d.Value

class AuthService {
  final AppDatabase database;
  // Notifier per l'ID utente corrente. Emette null se non loggato, altrimenti l'ID String.
  final ValueNotifier<String?> currentUserIdNotifier = ValueNotifier<String?>(null);

  AuthService(this.database);

  // Metodo per simulare il login o la creazione di un utente anonimo
  Future<void> signInAnonymously() async {
    try {
      // Prova a ottenere un utente esistente (es. se l'ID è persistente localmente)
      // Per semplicità, qui creiamo sempre un nuovo utente se non c'è un ID corrente.
      // In un'app reale, potresti leggere un ID salvato o usare un sistema di autenticazione.

      String? userId = currentUserIdNotifier.value;

      if (userId == null) {
        // Genera un nuovo ID utente (es. UUID)
        userId = DateTime.now().millisecondsSinceEpoch.toString(); // Semplice ID basato sul timestamp
                                                                  // In produzione usa un UUID reale: import 'package:uuid/uuid.dart'; var uuid = Uuid(); userId = uuid.v4();

        // Crea un nuovo utente nel database
        final newUserCompanion = d.UsersCompanion.insert(
          id: userId, // L'ID è ora una String
          name: 'Utente Anonimo $userId', // Nome di esempio
          email: d.Value(null), // Email opzionale
        );
        await database.createUser(newUserCompanion); // Questo metodo ora restituisce Future<void> o Future<int>

        // Aggiorna il notifier con il nuovo ID utente
        currentUserIdNotifier.value = userId;
        print('Utente anonimo creato e loggato con ID: $userId');
      } else {
        print('Utente già loggato con ID: $userId');
      }
    } catch (e) {
      print('Errore durante il login anonimo: $e');
      currentUserIdNotifier.value = null; // Assicurati che l'ID sia null in caso di errore
    }
  }

  // Metodo per il logout
  void signOut() {
    currentUserIdNotifier.value = null;
    print('Utente disconnesso.');
  }

  // Metodo per ottenere l'ID utente corrente (sincrono, usa il notifier per gli aggiornamenti)
  String? getCurrentUserId() {
    return currentUserIdNotifier.value;
  }
}
