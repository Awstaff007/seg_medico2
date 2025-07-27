// lib/services/api_service.dart
import 'dart:async';
import 'package:seg_medico/models/profilo.dart';

// Classe per simulare le informazioni del paziente restituite dall'API
class PatientInfo {
  final Profilo paziente;
  // Potresti aggiungere altri campi qui se la tua API ne restituisce
  // es: final List<dynamic> appointments;

  PatientInfo({required this.paziente});
}

class ApiService {
  // Mappa per simulare i codici OTP inviati (codiceFiscale-cellulare -> OTP)
  final Map<String, String> _otpCodes = {};
  // Mappa per simulare i token di autenticazione (codiceFiscale-cellulare -> token)
  final Map<String, String> _authTokens = {};
  // Mappa per simulare i profili utente nel "backend"
  final Map<String, Profilo> _backendProfiles = {
    // CORREZIONE: Aggiunto codiceFiscale alle istanze di Profilo
    'MRXYSN...-3331234567': Profilo(id: '1', nome: 'Mario', cognome: 'Rossi', cellulare: '3331234567', codiceFiscale: 'MRXYSN...'),
    'LSABNC...-3398765432': Profilo(id: '2', nome: 'Luisa', cognome: 'Bianchi', cellulare: '3398765432', codiceFiscale: 'LSABNC...'),
  };
  // Mappa per simulare gli appuntamenti associati ai profili
  final Map<String, List<Map<String, dynamic>>> _backendAppointments = {
    '1': [ // ID del profilo di Mario Rossi
      {'id': 'app1', 'date': '2025-07-28', 'time': '10:00', 'note': 'Controllo annuale'},
      {'id': 'app2', 'date': '2025-08-15', 'time': '14:30', 'note': 'Visita specialistica'},
    ],
    '2': [ // ID del profilo di Luisa Bianchi
      {'id': 'app3', 'date': '2025-07-29', 'time': '09:00', 'note': 'Controllo pressione'},
    ],
  };

  // Cooldown per l'invio dell'OTP
  DateTime? _lastOtpRequestTime;
  static const int _otpCooldownSeconds = 60;

  /// Simula la richiesta di un codice OTP.
  /// Restituisce true se la richiesta ha successo, false altrimenti.
  Future<bool> requestOtp(String codFis, String cellulare) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula latenza di rete

    final now = DateTime.now();
    if (_lastOtpRequestTime != null && now.difference(_lastOtpRequestTime!).inSeconds < _otpCooldownSeconds) {
      // Cooldown attivo
      return false;
    }

    final key = '$codFis-$cellulare';
    if (_backendProfiles.containsKey(key)) {
      // Simula l'invio di un OTP (es. "123456")
      _otpCodes[key] = '123456';
      _lastOtpRequestTime = now; // Aggiorna il tempo dell'ultima richiesta
      return true;
    }
    return false; // Profilo non trovato
  }

  /// Simula il processo di login con Codice Fiscale, Cellulare e OTP.
  /// Restituisce un token simulato se il login ha successo, altrimenti null.
  Future<String?> login(String codFis, String cellulare, String otpCode) async {
    await Future.delayed(const Duration(seconds: 2)); // Simula latenza di rete

    final key = '$codFis-$cellulare';
    if (_otpCodes.containsKey(key) && _otpCodes[key] == otpCode) {
      // OTP corretto, genera un token simulato
      final token = 'simulated_token_${DateTime.now().millisecondsSinceEpoch}';
      _authTokens[key] = token; // Memorizza il token simulato
      _otpCodes.remove(key); // Rimuovi l'OTP dopo l'uso
      return token;
    }
    return null; // OTP errato o non valido
  }

  /// Simula il recupero delle informazioni del paziente tramite token.
  Future<PatientInfo?> getPatientInfo(String token) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula latenza di rete

    // Trova il profilo associato al token simulato
    final entry = _authTokens.entries.firstWhere(
      (e) => e.value == token,
      orElse: () => const MapEntry('', ''), // Nessun token trovato
    );

    if (entry.key.isNotEmpty) {
      final profile = _backendProfiles[entry.key];
      if (profile != null) {
        return PatientInfo(paziente: profile);
      }
    }
    return null; // Token non valido o profilo non trovato
  }

  /// Simula il recupero degli appuntamenti per un dato profilo.
  Future<List<Map<String, dynamic>>> getAppointmentsForProfile(String profileId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula latenza di rete
    return _backendAppointments[profileId] ?? [];
  }

  /// Simula l'annullamento di un appuntamento.
  Future<bool> cancelAppointment(String appointmentId, String profileId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula latenza di rete
    final appointments = _backendAppointments[profileId];
    if (appointments != null) {
      final initialLength = appointments.length;
      appointments.removeWhere((app) => app['id'] == appointmentId);
      return appointments.length < initialLength; // True se un elemento è stato rimosso
    }
    return false;
  }

  /// Simula il recupero delle disponibilità per appuntamenti.
  Future<List<Map<String, dynamic>>> getAppointmentAvailability() async {
    await Future.delayed(const Duration(seconds: 1)); // Simula latenza di rete
    return [
      {'date': '2025-07-28', 'time': '10:00'},
      {'date': '2025-07-29', 'time': '14:00'},
      {'date': '2025-07-30', 'time': '09:30'},
      {'date': '2025-08-01', 'time': '11:00'},
    ];
  }

  /// Simula la prenotazione di un appuntamento.
  Future<bool> bookAppointment(String profileId, Map<String, dynamic> appointmentDetails) async {
    await Future.delayed(const Duration(seconds: 2)); // Simula latenza di rete
    final appointments = _backendAppointments.putIfAbsent(profileId, () => []);
    // Aggiungi un ID unico per l'appuntamento simulato
    appointmentDetails['id'] = 'new_app_${DateTime.now().millisecondsSinceEpoch}';
    appointments.add(appointmentDetails);
    return true; // Simula successo
  }

  /// Simula il recupero della lista farmaci.
  Future<List<Map<String, dynamic>>> getMedicationsForProfile(String profileId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula latenza di rete
    // Dati fittizi per i farmaci
    if (profileId == '1') { // Mario Rossi
      return [
        {'id': 'f1', 'name': 'Paracetamolo', 'checked': false},
        {'id': 'f2', 'name': 'Ibuprofene', 'checked': false},
        {'id': 'f3', 'name': 'Amoxicillina', 'checked': false},
      ];
    } else if (profileId == '2') { // Luisa Bianchi
      return [
        {'id': 'f4', 'name': 'Metformina', 'checked': false},
        {'id': 'f5', 'name': 'Insulina', 'checked': false},
      ];
    }
    return [];
  }

  /// Simula l'invio di un ordine farmaci.
  Future<bool> orderMedications(String profileId, List<String> medicationIds) async {
    await Future.delayed(const Duration(seconds: 2)); // Simula latenza di rete
    // Logica di simulazione: un ordine è sempre "successo"
    return true;
  }

  /// Simula il recupero della cronologia per un profilo.
  Future<List<Map<String, dynamic>>> getHistoryForProfile(String profileId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula latenza di rete
    // Dati fittizi per la cronologia
    if (profileId == '1') { // Mario Rossi
      return [
        {'date': '2025-07-15', 'type': 'Farmaco', 'description': 'Paracetamolo – febbre persistente'},
        {'date': '2025-07-08', 'type': 'Farmaco', 'description': 'Aspirina – dosaggio aumentato'},
        {'date': '2025-07-22', 'type': 'Appuntamento', 'description': 'Visita dermatologica – controllo nevi'},
      ];
    } else if (profileId == '2') { // Luisa Bianchi
      return [
        {'date': '2025-07-10', 'type': 'Appuntamento', 'description': 'Controllo diabetologico'},
      ];
    }
    return [];
  }
}
