// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

// --- Modelli di Dati ---

/// Rappresenta un profilo utente nell'applicazione.
class Profile {
  final String id;
  String name;
  String phoneNumber;
  String? authToken; // Token di autenticazione simulato, null se non loggato
  bool isDefault;

  Profile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.authToken,
    this.isDefault = false,
  });

  /// Converte un oggetto Profile in una mappa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'authToken': authToken,
        'isDefault': isDefault,
      };

  /// Crea un oggetto Profile da una mappa JSON.
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'],
        name: json['name'],
        phoneNumber: json['phoneNumber'],
        authToken: json['authToken'],
        isDefault: json['isDefault'] ?? false,
      );

  /// Crea una copia del profilo con eventuali modifiche.
  Profile copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? authToken,
    bool? isDefault,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authToken: authToken ?? this.authToken,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Override di == e hashCode per permettere al DropdownButton di confrontare correttamente i Profile
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Rappresenta un farmaco.
class Medication {
  final String id;
  String name;
  bool isSelected; // Per la pagina Farmaci

  Medication({required this.id, required this.name, this.isSelected = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isSelected': isSelected,
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'],
        name: json['name'],
        isSelected: json['isSelected'] ?? false,
      );

  Medication copyWith({String? id, String? name, bool? isSelected}) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Rappresenta un appuntamento.
class Appointment {
  final String id;
  DateTime dateTime;
  String notes;
  bool isBooked;

  Appointment({
    required this.id,
    required this.dateTime,
    this.notes = '',
    this.isBooked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'notes': notes,
        'isBooked': isBooked,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'],
        dateTime: DateTime.parse(json['dateTime']),
        notes: json['notes'] ?? '',
        isBooked: json['isBooked'] ?? false,
      );

  Appointment copyWith({
    String? id,
    DateTime? dateTime,
    String? notes,
    bool? isBooked,
  }) {
    return Appointment(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      isBooked: isBooked ?? this.isBooked,
    );
  }
}

/// Rappresenta una voce nella cronologia.
class HistoryEntry {
  final String id;
  final DateTime date;
  final String type; // e.g., 'Farmaco', 'Appuntamento'
  final String description;

  HistoryEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'type': type,
        'description': description,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'],
        date: DateTime.parse(json['date']),
        type: json['type'],
        description: json['description'],
      );
}

// --- Servizi (Mock API e Storage Locale) ---

/// Servizio per la gestione dello storage locale tramite SharedPreferences.
class LocalStorageService {
  static const String _profilesKey = 'profiles';
  static const String _settingsKey = 'settings';
  static const String _historyKey = 'history';

  /// Carica tutti i profili salvati.
  Future<List<Profile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? profilesJson = prefs.getString(_profilesKey);
    if (profilesJson == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(profilesJson);
    return jsonList.map((json) => Profile.fromJson(json)).toList();
  }

  /// Salva la lista di profili.
  Future<void> saveProfiles(List<Profile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final String profilesJson =
        jsonEncode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_profilesKey, profilesJson);
  }

  /// Carica le impostazioni dell'app.
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString(_settingsKey);
    if (settingsJson == null) {
      return {};
    }
    return jsonDecode(settingsJson);
  }

  /// Salva le impostazioni dell'app.
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  /// Carica la cronologia.
  Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);
    if (historyJson == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(historyJson);
    return jsonList.map((json) => HistoryEntry.fromJson(json)).toList();
  }

  /// Salva la cronologia.
  Future<void> saveHistory(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final String historyJson =
        jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, historyJson);
  }
}

/// Servizio di autenticazione simulato.
class MockAuthService with ChangeNotifier {
  // Simula un database di utenti con numeri di telefono e token
  final Map<String, String> _userTokens = {}; // phoneNumber: authToken

  /// Simula la richiesta di un codice SMS.
  Future<String> requestSmsCode(String phoneNumber) async {
    // In un'applicazione reale, qui ci sarebbe una chiamata API.
    await Future.delayed(const Duration(seconds: 2)); // Simula il ritardo di rete
    if (phoneNumber == '331234567') {
      return '123456'; // Codice fisso per test
    } else {
      throw Exception('Numero di telefono non registrato.');
    }
  }

  /// Simula la verifica del codice SMS.
  Future<String> verifySmsCode(String phoneNumber, String code) async {
    await Future.delayed(const Duration(seconds: 2));
    if (phoneNumber == '331234567' && code == '123456') {
      final newToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      _userTokens[phoneNumber] = newToken;
      return newToken;
    } else if (code == 'expired') {
      throw Exception('Codice scaduto.');
    } else {
      throw Exception('Codice errato.');
    }
  }

  /// Simula il logout.
  Future<void> logout(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 1));
    _userTokens.remove(phoneNumber);
  }
}

/// Servizio API simulato per appuntamenti e farmaci.
class MockApiService {
  /// Simula il recupero delle disponibilità per gli appuntamenti.
  Future<List<Appointment>> fetchAppointmentAvailability() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Appointment(
          id: '1',
          dateTime: DateTime.now().add(const Duration(days: 3, hours: 10)),
          notes: 'Controllo generale'),
      Appointment(
          id: '2',
          dateTime: DateTime.now().add(const Duration(days: 4, hours: 14)),
          notes: 'Visita specialistica'),
      Appointment(
          id: '3',
          dateTime: DateTime.now().add(const Duration(days: 5, hours: 9, minutes: 30)),
          notes: 'Esami del sangue'),
    ];
  }

  /// Simula la prenotazione di un appuntamento.
  Future<bool> bookAppointment(Appointment appointment) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simula successo o fallimento casuale
    if (Random().nextBool()) {
      return true; // Successo
    } else {
      throw Exception('Errore durante la prenotazione dell\'appuntamento.');
    }
  }

  /// Simula la cancellazione di un appuntamento.
  Future<bool> cancelAppointment(String appointmentId) async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // Sempre successo per la simulazione
  }

  /// Simula l'invio di un ordine di farmaci.
  Future<bool> sendMedicationOrder(List<Medication> medications) async {
    await Future.delayed(const Duration(seconds: 2));
    if (Random().nextBool()) {
      return true; // Successo
    } else {
      throw Exception('Errore durante l\'invio dell\'ordine.');
    }
  }
}

// --- Gestione dello Stato (Providers) ---

/// Gestisce i profili utente e lo stato di autenticazione.
class ProfileProvider with ChangeNotifier {
  final LocalStorageService _localStorageService;
  final MockAuthService _authService;
  List<Profile> _profiles = [];
  Profile? _currentProfile;
  bool _isLoading = false;

  ProfileProvider(this._localStorageService, this._authService) {
    _loadProfiles();
  }

  List<Profile> get profiles => _profiles;
  Profile? get currentProfile => _currentProfile;
  bool get isAuthenticated => _currentProfile?.authToken != null;
  bool get isLoading => _isLoading;

  /// Carica i profili da storage locale all'avvio.
  Future<void> _loadProfiles() async {
    _profiles = await _localStorageService.loadProfiles();
    _currentProfile = _profiles.firstWhereOrNull((p) => p.isDefault);
    if (_currentProfile == null && _profiles.isNotEmpty) {
      _currentProfile = _profiles.first; // Seleziona il primo se non c'è un default
    }
    // Simulate login for the default profile if it has an auth token
    if (_currentProfile != null && _currentProfile!.authToken != null) {
      // In a real app, you might validate the token here.
      // For this mock, we just assume it's valid if present.
      print('Profilo ${_currentProfile!.name} caricato e considerato loggato.');
    } else if (_profiles.isEmpty) {
      // Add a default profile if none exists for easier testing
      final defaultTestProfile = Profile(
        id: 'test_user_1',
        name: 'Mario Rossi',
        phoneNumber: '331234567',
        isDefault: true,
        authToken: 'mock_token_initial_login', // Pre-logged in for demo
      );
      _profiles.add(defaultTestProfile);
      _currentProfile = defaultTestProfile;
      await _saveProfiles();
      print('Profilo di test "Mario Rossi" creato e pre-loggato.');
    }
    notifyListeners();
  }

  /// Salva i profili nello storage locale.
  Future<void> _saveProfiles() async {
    await _localStorageService.saveProfiles(_profiles);
  }

  /// Aggiunge un nuovo profilo.
  Future<void> addProfile(Profile profile) async {
    _profiles.add(profile);
    await _saveProfiles();
    notifyListeners();
  }

  /// Aggiorna un profilo esistente.
  Future<void> updateProfile(Profile updatedProfile) async {
    final index = _profiles.indexWhere((p) => p.id == updatedProfile.id);
    if (index != -1) {
      _profiles[index] = updatedProfile;
      if (_currentProfile?.id == updatedProfile.id) {
        _currentProfile = updatedProfile;
      }
      await _saveProfiles();
      notifyListeners();
    }
  }

  /// Elimina un profilo.
  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((p) => p.id == profileId);
    if (_currentProfile?.id == profileId) {
      _currentProfile = null; // Se il profilo eliminato era quello corrente, deselezionalo
    }
    await _saveProfiles();
    notifyListeners();
  }

  /// Seleziona un profilo come corrente.
  Future<void> selectProfile(Profile? profile) async {
    _currentProfile = profile;
    // Aggiorna lo stato di default per i profili
    _profiles = _profiles.map((p) => p.copyWith(isDefault: p.id == profile?.id)).toList();
    await _saveProfiles();
    notifyListeners();
  }

  /// Tenta il login per il profilo corrente.
  Future<void> loginCurrentProfile(String code) async {
    if (_currentProfile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authService.verifySmsCode(
          _currentProfile!.phoneNumber, code);
      _currentProfile = _currentProfile!.copyWith(authToken: token);
      await updateProfile(_currentProfile!); // Salva il token nel profilo
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Effettua il logout del profilo corrente.
  Future<void> logoutCurrentProfile() async {
    if (_currentProfile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout(_currentProfile!.phoneNumber);
      _currentProfile = _currentProfile!.copyWith(authToken: null);
      await updateProfile(_currentProfile!); // Rimuovi il token dal profilo
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// Gestisce le impostazioni dell'applicazione.
class SettingsProvider with ChangeNotifier {
  final LocalStorageService _localStorageService;

  double _textSizeMultiplier = 1.0; // 1.0 = 100%, 1.5 = 150%
  bool _medicationRepetitionEnabled = false;
  int _medicationRepetitionDays = 30;
  bool _appointmentDayBeforeReminderEnabled = false;
  bool _appointmentMinutesBeforeReminderEnabled = false;
  int _appointmentMinutesBefore = 30; // 30, 60, 90, 120
  bool _pushNotificationsEnabled = true; // Simulato
  String _themeMode = 'Chiaro'; // 'Chiaro' o 'Scuro'

  SettingsProvider(this._localStorageService) {
    _loadSettings();
  }

  double get textSizeMultiplier => _textSizeMultiplier;
  bool get medicationRepetitionEnabled => _medicationRepetitionEnabled;
  int get medicationRepetitionDays => _medicationRepetitionDays;
  bool get appointmentDayBeforeReminderEnabled =>
      _appointmentDayBeforeReminderEnabled;
  bool get appointmentMinutesBeforeReminderEnabled =>
      _appointmentMinutesBeforeReminderEnabled;
  int get appointmentMinutesBefore => _appointmentMinutesBefore;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  String get themeMode => _themeMode;

  /// Carica le impostazioni da storage locale.
  Future<void> _loadSettings() async {
    final settings = await _localStorageService.loadSettings();
    _textSizeMultiplier = settings['textSizeMultiplier'] ?? 1.0;
    _medicationRepetitionEnabled =
        settings['medicationRepetitionEnabled'] ?? false;
    _medicationRepetitionDays = settings['medicationRepetitionDays'] ?? 30;
    _appointmentDayBeforeReminderEnabled =
        settings['appointmentDayBeforeReminderEnabled'] ?? false;
    _appointmentMinutesBeforeReminderEnabled =
        settings['appointmentMinutesBeforeReminderEnabled'] ?? false;
    _appointmentMinutesBefore = settings['appointmentMinutesBefore'] ?? 30;
    _pushNotificationsEnabled = settings['pushNotificationsEnabled'] ?? true;
    _themeMode = settings['themeMode'] ?? 'Chiaro';
    notifyListeners();
  }

  /// Salva tutte le impostazioni.
  Future<void> saveSettings() async {
    final settings = {
      'textSizeMultiplier': _textSizeMultiplier,
      'medicationRepetitionEnabled': _medicationRepetitionEnabled,
      'medicationRepetitionDays': _medicationRepetitionDays,
      'appointmentDayBeforeReminderEnabled': _appointmentDayBeforeReminderEnabled,
      'appointmentMinutesBeforeReminderEnabled':
          _appointmentMinutesBeforeReminderEnabled,
      'appointmentMinutesBefore': _appointmentMinutesBefore,
      'pushNotificationsEnabled': _pushNotificationsEnabled,
      'themeMode': _themeMode,
    };
    await _localStorageService.saveSettings(settings);
    notifyListeners();
  }

  void setTextSizeMultiplier(double value) {
    _textSizeMultiplier = value;
    notifyListeners();
  }

  void setMedicationRepetitionEnabled(bool value) {
    _medicationRepetitionEnabled = value;
    notifyListeners();
  }

  void setMedicationRepetitionDays(int value) {
    _medicationRepetitionDays = value;
    notifyListeners();
  }

  void setAppointmentDayBeforeReminderEnabled(bool value) {
    _appointmentDayBeforeReminderEnabled = value;
    if (!value) {
      // Se disabilitato, disabilita anche l'avviso minuti prima
      _appointmentMinutesBeforeReminderEnabled = false;
    }
    notifyListeners();
  }

  void setAppointmentMinutesBeforeReminderEnabled(bool value) {
    _appointmentMinutesBeforeReminderEnabled = value;
    notifyListeners();
  }

  void setAppointmentMinutesBefore(int value) {
    _appointmentMinutesBefore = value;
    notifyListeners();
  }

  void setPushNotificationsEnabled(bool value) {
    _pushNotificationsEnabled = value;
    notifyListeners();
  }

  void setThemeMode(String value) {
    _themeMode = value;
    notifyListeners();
  }
}

/// Gestisce i farmaci e le operazioni correlate.
class MedicationProvider with ChangeNotifier {
  final MockApiService _apiService;
  List<Medication> _medications = [];
  bool _isLoading = false;

  MedicationProvider(this._apiService) {
    // Carica farmaci di esempio all'avvio
    _medications = [
      Medication(id: 'm1', name: 'Farmaco 1'),
      Medication(id: 'm2', name: 'Farmaco 2'),
      Medication(id: 'm3', name: 'Farmaco 3'),
      Medication(id: 'm4', name: 'Farmaco 4'),
    ];
  }

  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;

  void toggleMedicationSelection(String id, bool isSelected) {
    final index = _medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      _medications[index] = _medications[index].copyWith(isSelected: isSelected);
      notifyListeners();
    }
  }

  Future<bool> sendOrder() async {
    _isLoading = true;
    notifyListeners();
    try {
      final selectedMedications = _medications.where((m) => m.isSelected).toList();
      final success = await _apiService.sendMedicationOrder(selectedMedications);
      if (success) {
        // Resetta la selezione dopo l'invio
        _medications = _medications.map((m) => m.copyWith(isSelected: false)).toList();
      }
      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// Gestisce gli appuntamenti.
class AppointmentProvider with ChangeNotifier {
  final MockApiService _apiService;
  Appointment? _nextAppointment; // Prossimo appuntamento prenotato
  List<Appointment> _availableAppointments = [];
  bool _isLoading = false;

  AppointmentProvider(this._apiService);

  Appointment? get nextAppointment => _nextAppointment;
  List<Appointment> get availableAppointments => _availableAppointments;
  bool get isLoading => _isLoading;

  /// Simula il caricamento del prossimo appuntamento (se esiste).
  Future<void> loadNextAppointment() async {
    // In un'app reale, questo verrebbe caricato da storage locale o API
    // Per questa simulazione, lo impostiamo manualmente se non esiste già
    if (_nextAppointment == null) {
      _nextAppointment = Appointment(
        id: 'app1',
        dateTime: DateTime.now().add(const Duration(days: 1, hours: 14)),
        notes: 'Chiedere dosaggio nuovo farmaco',
        isBooked: true,
      );
    }
    notifyListeners();
  }

  /// Carica le disponibilità degli appuntamenti dall'API simulata.
  Future<void> fetchAvailableAppointments() async {
    _isLoading = true;
    notifyListeners();
    try {
      _availableAppointments = await _apiService.fetchAppointmentAvailability();
    } catch (e) {
      _availableAppointments = []; // In caso di errore
      print('Errore nel caricamento disponibilità: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Prenota un appuntamento.
  Future<bool> bookAppointment(Appointment appointment) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _apiService.bookAppointment(appointment);
      if (success) {
        _nextAppointment = appointment.copyWith(isBooked: true);
        // Rimuovi l'appuntamento prenotato dalle disponibilità
        _availableAppointments.removeWhere((a) => a.id == appointment.id);
      }
      return success;
    } catch (e) {
      print('Errore durante la prenotazione: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancella il prossimo appuntamento.
  Future<bool> cancelNextAppointment() async {
    if (_nextAppointment == null) return false;

    _isLoading = true;
    notifyListeners();
    try {
      final success = await _apiService.cancelAppointment(_nextAppointment!.id);
      if (success) {
        _nextAppointment = null;
      }
      return success;
    } catch (e) {
      print('Errore durante la cancellazione: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// Gestisce la cronologia delle attività.
class HistoryProvider with ChangeNotifier {
  final LocalStorageService _localStorageService;
  List<HistoryEntry> _history = [];
  String _searchQuery = '';
  DateTime? _filterDate;

  HistoryProvider(this._localStorageService) {
    _loadHistory();
  }

  List<HistoryEntry> get history => _history;
  String get searchQuery => _searchQuery;
  DateTime? get filterDate => _filterDate;

  /// Carica la cronologia da storage locale.
  Future<void> _loadHistory() async {
    _history = await _localStorageService.loadHistory();
    notifyListeners();
  }

  /// Aggiunge una voce alla cronologia.
  Future<void> addHistoryEntry(HistoryEntry entry) async {
    _history.insert(0, entry); // Aggiungi in cima
    await _localStorageService.saveHistory(_history);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  /// Filtra e ordina la cronologia.
  List<HistoryEntry> get filteredHistory {
    List<HistoryEntry> filtered = _history;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((entry) =>
              entry.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              entry.type.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_filterDate != null) {
      filtered = filtered
          .where((entry) =>
              entry.date.year == _filterDate!.year &&
              entry.date.month == _filterDate!.month &&
              entry.date.day == _filterDate!.day)
          .toList();
    }

    // Ordina per data decrescente
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }
}

// --- Funzione Main e Setup dell'App ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza i servizi
  final localStorageService = LocalStorageService();
  final mockAuthService = MockAuthService();
  final mockApiService = MockApiService();

  // Inizializza i providers
  final profileProvider = ProfileProvider(localStorageService, mockAuthService);
  final settingsProvider = SettingsProvider(localStorageService);
  final medicationProvider = MedicationProvider(mockApiService);
  final appointmentProvider = AppointmentProvider(mockApiService);
  final historyProvider = HistoryProvider(localStorageService);

  // Carica i dati iniziali
  await profileProvider.profiles; // Assicurati che i profili siano caricati
  await settingsProvider.textSizeMultiplier; // Assicurati che le impostazioni siano caricate
  await appointmentProvider.loadNextAppointment(); // Carica il prossimo appuntamento
  await historyProvider.history; // Carica la cronologia

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => profileProvider),
        ChangeNotifierProvider(create: (_) => settingsProvider),
        ChangeNotifierProvider(create: (_) => medicationProvider),
        ChangeNotifierProvider(create: (_) => appointmentProvider),
        ChangeNotifierProvider(create: (_) => historyProvider),
        ChangeNotifierProvider(create: (_) => mockAuthService), // Aggiunto MockAuthService qui
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ascolta i cambiamenti nel tema dalle impostazioni
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeMode = settingsProvider.themeMode == 'Scuro' ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp(
      title: 'App per Anziani',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Utilizzo del font Inter
        // Stile generale dei bottoni
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: TextStyle(fontSize: 16 * settingsProvider.textSizeMultiplier),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: TextStyle(fontSize: 16 * settingsProvider.textSizeMultiplier),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        appBarTheme: AppBarTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
          elevation: 4,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // fontFamily: 'Inter', // Removed as it's not a direct parameter here
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: TextStyle(fontSize: 16 * settingsProvider.textSizeMultiplier),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: TextStyle(fontSize: 16 * settingsProvider.textSizeMultiplier),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        appBarTheme: AppBarTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
          elevation: 4,
        ),
      ),
      themeMode: themeMode,
      home: const HomePage(),
      routes: {
        '/manage_profiles': (context) => const ManageProfilesPage(),
        '/medications': (context) => const MedicationsPage(),
        '/appointments': (context) => const AppointmentsPage(),
        '/history': (context) => const HistoryPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

// --- Layout Comune (Side Menu) ---

/// Widget per il menu laterale.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28 * textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                if (profileProvider.isAuthenticated)
                  Text(
                    'Profilo: ${profileProvider.currentProfile?.name ?? 'Nessuno'}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16 * textSizeMultiplier,
                    ),
                  ),
              ],
            ),
          ),
          // Aggiunto "Home" al menu laterale
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home',
            route: '/',
            isEnabled: true, // Home è sempre accessibile
            textSizeMultiplier: textSizeMultiplier,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            title: 'Cronologia',
            route: '/history',
            isEnabled: profileProvider.isAuthenticated,
            textSizeMultiplier: textSizeMultiplier,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.medical_services,
            title: 'Farmaci',
            route: '/medications',
            isEnabled: profileProvider.isAuthenticated,
            textSizeMultiplier: textSizeMultiplier,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today,
            title: 'Appuntamenti',
            route: '/appointments',
            isEnabled: profileProvider.isAuthenticated,
            textSizeMultiplier: textSizeMultiplier,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Impostazioni',
            route: '/settings',
            isEnabled: true, // Le impostazioni sono sempre accessibili
            textSizeMultiplier: textSizeMultiplier,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isEnabled,
    required double textSizeMultiplier,
  }) {
    return ListTile(
      leading: Icon(icon, color: isEnabled ? Theme.of(context).iconTheme.color : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18 * textSizeMultiplier,
          color: isEnabled ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
        ),
      ),
      onTap: isEnabled
          ? () {
              Navigator.pop(context); // Chiudi il drawer
              // Usa pushReplacementNamed per evitare di impilare la Home più volte
              if (ModalRoute.of(context)?.settings.name == route) {
                // Se siamo già sulla pagina, non fare nulla o semplicemente chiudi il drawer
                return;
              }
              Navigator.pushReplacementNamed(context, route);
            }
          : () {
              Navigator.pop(context); // Chiudi il drawer
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Accedi per accedere a questa sezione.',
                    style: TextStyle(fontSize: 14 * textSizeMultiplier),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
    );
  }
}

// --- Schermate dell'App ---

/// 1. HOME - PRIMA/DOPO IL LOGIN
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Carica il prossimo appuntamento all'avvio della Home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).loadNextAppointment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    final isAuthenticated = profileProvider.isAuthenticated;
    final currentProfile = profileProvider.currentProfile;
    final nextAppointment = appointmentProvider.nextAppointment;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            // Icona per cambiare dimensione caratteri globalmente
            IconButton(
              icon: Icon(Icons.format_size, size: 28 * textSizeMultiplier),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const SizedBox(width: 8),
            // Dropdown per selezionare profilo
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Profile>(
                  value: currentProfile,
                  hint: Text(
                    'Seleziona profilo',
                    style: TextStyle(fontSize: 18 * textSizeMultiplier),
                  ),
                  onChanged: (Profile? newValue) {
                    profileProvider.selectProfile(newValue);
                  },
                  items: profileProvider.profiles.map<DropdownMenuItem<Profile>>((Profile profile) {
                    return DropdownMenuItem<Profile>(
                      value: profile,
                      child: Text(
                        profile.name,
                        style: TextStyle(fontSize: 18 * textSizeMultiplier),
                      ),
                    );
                  }).toList(),
                  isExpanded: true,
                  style: TextStyle(
                    fontSize: 18 * textSizeMultiplier,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Pulsante "Gestisci profili"
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/manage_profiles');
              },
              icon: Icon(Icons.people_alt, size: 20 * textSizeMultiplier),
              label: Text(
                'Gestisci profili',
                style: TextStyle(fontSize: 16 * textSizeMultiplier),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            // Pulsante "Esci" (visibile solo dopo il login)
            if (isAuthenticated)
              ElevatedButton.icon(
                onPressed: () async {
                  await profileProvider.logoutCurrentProfile();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Logout effettuato.',
                        style: TextStyle(fontSize: 14 * textSizeMultiplier),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: Icon(Icons.logout, size: 20 * textSizeMultiplier),
                label: Text(
                  'Esci',
                  style: TextStyle(fontSize: 16 * textSizeMultiplier),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
        toolbarHeight: 80, // Aumenta l'altezza della AppBar per contenere tutti gli elementi
      ),
      drawer: const AppDrawer(), // Menu laterale
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prossima visita
            if (nextAppointment != null &&
                nextAppointment.dateTime.isAfter(DateTime.now()))
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prossima visita:',
                        style: TextStyle(
                          fontSize: 20 * textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatDate(nextAppointment.dateTime)}, ore ${_formatTime(nextAppointment.dateTime)}',
                        style: TextStyle(fontSize: 18 * textSizeMultiplier),
                      ),
                      if (nextAppointment.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '↪ Note: "${nextAppointment.notes}"',
                            style: TextStyle(
                              fontSize: 16 * textSizeMultiplier,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await _showConfirmationDialog(
                              context,
                              'Conferma Cancellazione',
                              'Sei sicuro di voler annullare la prossima visita?',
                            );
                            if (confirmed == true) {
                              final success = await appointmentProvider.cancelNextAppointment();
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Visita annullata con successo.',
                                      style: TextStyle(fontSize: 14 * textSizeMultiplier),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Errore durante l\'annullamento della visita.',
                                      style: TextStyle(fontSize: 14 * textSizeMultiplier),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.cancel, size: 20 * textSizeMultiplier),
                          label: Text(
                            'Annulla visita',
                            style: TextStyle(fontSize: 16 * textSizeMultiplier),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Ripetizione farmaci
            Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                if (settings.medicationRepetitionEnabled) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.repeat, size: 24 * textSizeMultiplier),
                          const SizedBox(width: 12),
                          Text(
                            'Ripetizione farmaci tra ${settings.medicationRepetitionDays} giorni',
                            style: TextStyle(fontSize: 18 * textSizeMultiplier),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink(); // Nascondi se disabilitato
              },
            ),
            const Spacer(),
            // Pulsante "ACCEDI a Mario"
            Center(
              child: ElevatedButton(
                onPressed: currentProfile != null && !isAuthenticated
                    ? () {
                        _showLoginDialog(context, currentProfile);
                      }
                    : null, // Disabilitato se nessun profilo selezionato o già autenticato
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: isAuthenticated ? Colors.grey : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isAuthenticated
                      ? 'Accesso Effettuato'
                      : (currentProfile != null ? 'ACCEDI a ${currentProfile.name}' : 'Seleziona un profilo'),
                  style: TextStyle(fontSize: 20 * textSizeMultiplier),
                ),
              ),
            ),
            const Spacer(),
            // Rimossa la sezione del menu in basso a destra
          ],
        ),
      ),
    );
  }

  /// Mostra il popup di login.
  void _showLoginDialog(BuildContext context, Profile? profile) {
    if (profile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return LoginDialog(profile: profile);
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'Gen',
      'Feb',
      'Mar',
      'Apr',
      'Mag',
      'Giu',
      'Lug',
      'Ago',
      'Set',
      'Ott',
      'Nov',
      'Dic'
    ];
    return monthNames[month];
  }

  /// Mostra un dialog di conferma personalizzato.
  Future<bool?> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: TextStyle(fontSize: 20 * textSizeMultiplier),
          ),
          content: Text(
            content,
            style: TextStyle(fontSize: 16 * textSizeMultiplier),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Annulla',
                style: TextStyle(fontSize: 16 * textSizeMultiplier),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Conferma',
                style: TextStyle(fontSize: 16 * textSizeMultiplier),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 2. POPUP LOGIN - RICHIEDI CODICE / 3. POPUP LOGIN - INSERISCI CODICE
class LoginDialog extends StatefulWidget {
  final Profile profile;

  const LoginDialog({super.key, required this.profile});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  bool _requestingCode = false;
  bool _codeSent = false;
  String? _errorMessage;
  final TextEditingController _codeController = TextEditingController();
  int _cooldownSeconds = 0;
  DateTime? _lastRequestTime;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Richiede il codice SMS.
  Future<void> _requestCode() async {
    if (_requestingCode || _cooldownSeconds > 0) return;

    final now = DateTime.now();
    if (_lastRequestTime != null && now.difference(_lastRequestTime!).inSeconds < 60) {
      setState(() {
        _errorMessage = 'Limite raggiunto. Riprova tra ${60 - now.difference(_lastRequestTime!).inSeconds} secondi.';
      });
      return;
    }

    setState(() {
      _requestingCode = true;
      _errorMessage = null;
    });

    try {
      await Provider.of<MockAuthService>(context, listen: false)
          .requestSmsCode(widget.profile.phoneNumber);
      setState(() {
        _codeSent = true;
        _cooldownSeconds = 60;
        _lastRequestTime = now;
        _startCooldownTimer();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _requestingCode = false;
      });
    }
  }

  /// Avvia il timer di cooldown per il codice SMS.
  void _startCooldownTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
        _startCooldownTimer();
      }
    });
  }

  /// Verifica il codice SMS.
  Future<void> _verifyCode() async {
    if (_requestingCode) return;

    setState(() {
      _requestingCode = true;
      _errorMessage = null;
    });

    try {
      await Provider.of<ProfileProvider>(context, listen: false)
          .loginCurrentProfile(_codeController.text);
      Navigator.of(context).pop(); // Chiudi il popup
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Accesso a ${widget.profile.name} effettuato con successo!',
            style: TextStyle(fontSize: 14 * Provider.of<SettingsProvider>(context, listen: false).textSizeMultiplier),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _requestingCode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.profile.name,
        style: TextStyle(fontSize: 24 * textSizeMultiplier, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Telefono: ${widget.profile.phoneNumber}',
              style: TextStyle(fontSize: 18 * textSizeMultiplier),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!_codeSent)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _requestingCode || _cooldownSeconds > 0 ? null : _requestCode,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _requestingCode
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _cooldownSeconds > 0
                                ? 'Reinvia (${_cooldownSeconds}s)'
                                : 'RICHIEDI CODICE SMS',
                            style: TextStyle(fontSize: 18 * textSizeMultiplier),
                          ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 14 * textSizeMultiplier),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    'Inserisci codice SMS (6 cifre)',
                    style: TextStyle(fontSize: 16 * textSizeMultiplier),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24 * textSizeMultiplier, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '______',
                      counterText: '', // Nasconde il contatore dei caratteri
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 6) {
                        FocusScope.of(context).unfocus(); // Chiudi la tastiera
                      }
                    },
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 14 * textSizeMultiplier),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _requestingCode || _codeController.text.length != 6
                        ? null
                        : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _requestingCode
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'ACCEDI',
                            style: TextStyle(fontSize: 18 * textSizeMultiplier),
                          ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Chiudi il popup
          },
          child: Text(
            'ANNULLA',
            style: TextStyle(fontSize: 16 * textSizeMultiplier),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}

/// 4. HOME - DOPO IL LOGIN (gestita dalla HomePage con logica condizionale)

/// 5. PAGINA FARMACI
class MedicationsPage extends StatefulWidget {
  const MedicationsPage({super.key});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  bool _isEditing = false;
  List<Medication> _tempMedications = []; // Per le modifiche temporanee

  @override
  void initState() {
    super.initState();
    // Inizializza _tempMedications con i farmaci attuali
    _tempMedications = List.from(
        Provider.of<MedicationProvider>(context, listen: false).medications);
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Se si esce dalla modalità modifica, resetta le selezioni temporanee
        _tempMedications = List.from(
            Provider.of<MedicationProvider>(context, listen: false).medications);
      }
    });
  }

  void _toggleMedicationSelection(String id, bool? isSelected) {
    if (isSelected == null) return;
    setState(() {
      final index = _tempMedications.indexWhere((m) => m.id == id);
      if (index != -1) {
        _tempMedications[index] = _tempMedications[index].copyWith(isSelected: isSelected);
      }
    });
  }

  Future<void> _sendOrder() async {
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    // Applica le selezioni da _tempMedications a medicationProvider
    for (var med in _tempMedications) {
      medicationProvider.toggleMedicationSelection(med.id, med.isSelected);
    }

    final success = await medicationProvider.sendOrder();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ordine inviato con successo!',
            style: TextStyle(fontSize: 14 * textSizeMultiplier),
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Aggiungi alla cronologia
      final selectedNames = _tempMedications.where((m) => m.isSelected).map((m) => m.name).join(', ');
      historyProvider.addHistoryEntry(
        HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          type: 'Farmaco',
          description: 'Ordine farmaci: $selectedNames',
        ),
      );
      setState(() {
        _isEditing = false; // Esci dalla modalità modifica dopo l'invio
        _tempMedications = List.from(medicationProvider.medications); // Sincronizza di nuovo
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore, riprova l\'invio dell\'ordine.',
            style: TextStyle(fontSize: 14 * textSizeMultiplier),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final medicationProvider = Provider.of<MedicationProvider>(context);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Farmaci',
              style: TextStyle(fontSize: 24 * textSizeMultiplier, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // Pulsante Modifica
            ElevatedButton.icon(
              onPressed: _toggleEditing,
              icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 20 * textSizeMultiplier),
              label: Text(
                _isEditing ? 'Fatto' : 'Modifica',
                style: TextStyle(fontSize: 16 * textSizeMultiplier),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? Colors.green : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(), // Aggiunto il drawer qui
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _isEditing ? _tempMedications.length : medicationProvider.medications.length,
                itemBuilder: (context, index) {
                  final medication = _isEditing ? _tempMedications[index] : medicationProvider.medications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          if (_isEditing)
                            Checkbox(
                              value: medication.isSelected,
                              onChanged: (bool? value) {
                                _toggleMedicationSelection(medication.id, value);
                              },
                            ),
                          Expanded(
                            child: Text(
                              medication.name,
                              style: TextStyle(fontSize: 18 * textSizeMultiplier),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Note personali collassabili
            ExpansionTile(
              title: Text(
                'Note personali',
                style: TextStyle(fontSize: 18 * textSizeMultiplier, fontWeight: FontWeight.bold),
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Aggiungi note personali qui...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(fontSize: 16 * textSizeMultiplier),
                    onChanged: (text) {
                      // Qui potresti salvare le note localmente o in un provider dedicato
                      // Per semplicità, non le salviamo in questo esempio
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Pulsanti Ordina e Annulla (visibili solo in modalità modifica)
            if (_isEditing)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: medicationProvider.isLoading ? null : _sendOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: medicationProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'ORDINA',
                              style: TextStyle(fontSize: 18 * textSizeMultiplier),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _toggleEditing, // Annulla le modifiche e esce dalla modalità modifica
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'ANNULLA',
                        style: TextStyle(fontSize: 18 * textSizeMultiplier),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 6. PAGINA APPUNTAMENTI
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  Appointment? _selectedAvailableAppointment;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carica le disponibilità all'ingresso nella pagina
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).fetchAvailableAppointments();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bookAppointment() async {
    if (_selectedAvailableAppointment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seleziona una disponibilità per prenotare.',
            style: TextStyle(fontSize: 14 * Provider.of<SettingsProvider>(context, listen: false).textSizeMultiplier),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    final newAppointment = _selectedAvailableAppointment!.copyWith(notes: _notesController.text);

    final success = await appointmentProvider.bookAppointment(newAppointment);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Appuntamento prenotato con successo!',
            style: TextStyle(fontSize: 14 * textSizeMultiplier),
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Aggiungi alla cronologia
      historyProvider.addHistoryEntry(
        HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: newAppointment.dateTime,
          type: 'Appuntamento',
          description: 'Visita prenotata: ${_formatDate(newAppointment.dateTime)} - ${newAppointment.notes}',
        ),
      );
      Navigator.pop(context); // Torna alla home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore durante la prenotazione, riprova.',
            style: TextStyle(fontSize: 14 * textSizeMultiplier),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'Gen',
      'Feb',
      'Mar',
      'Apr',
      'Mag',
      'Giu',
      'Lug',
      'Ago',
      'Set',
      'Ott',
      'Nov',
      'Dic'
    ];
    return monthNames[month];
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appuntamenti',
          style: TextStyle(fontSize: 24 * textSizeMultiplier, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: const AppDrawer(), // Aggiunto il drawer qui
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disponibilità via API:',
              style: TextStyle(fontSize: 20 * textSizeMultiplier, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            appointmentProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : appointmentProvider.availableAppointments.isEmpty
                    ? Text(
                        'Nessuna disponibilità trovata.',
                        style: TextStyle(fontSize: 16 * textSizeMultiplier, fontStyle: FontStyle.italic),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: appointmentProvider.availableAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = appointmentProvider.availableAppointments[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              color: _selectedAvailableAppointment?.id == appointment.id
                                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                                  : null,
                              child: ListTile(
                                title: Text(
                                  '${_formatDate(appointment.dateTime)} – ${_formatTime(appointment.dateTime)}',
                                  style: TextStyle(fontSize: 18 * textSizeMultiplier),
                                ),
                                subtitle: Text(
                                  appointment.notes,
                                  style: TextStyle(fontSize: 14 * textSizeMultiplier),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedAvailableAppointment = appointment;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _selectedAvailableAppointment?.id == appointment.id
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 24),
            Text(
              '✏️ Note visita:',
              style: TextStyle(fontSize: 20 * textSizeMultiplier, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Aggiungi note per la visita...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(fontSize: 16 * textSizeMultiplier),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: appointmentProvider.isLoading ? null : _bookAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: appointmentProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'PRENOTA',
                            style: TextStyle(fontSize: 18 * textSizeMultiplier),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Torna alla home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'ANNULLA',
                      style: TextStyle(fontSize: 18 * textSizeMultiplier),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 7. PAGINA CRONOLOGIA
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<HistoryProvider>(context, listen: false)
          .setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      Provider.of<HistoryProvider>(context, listen: false).setFilterDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final historyProvider = Provider.of<HistoryProvider>(context);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cerca nella cronologia...',
                  hintStyle: TextStyle(fontSize: 16 * textSizeMultiplier),
                  prefixIcon: Icon(Icons.search, size: 20 * textSizeMultiplier),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                style: TextStyle(fontSize: 16 * textSizeMultiplier),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.calendar_today, size: 24 * textSizeMultiplier),
              onPressed: () => _selectDate(context),
            ),
            if (historyProvider.filterDate != null)
              IconButton(
                icon: Icon(Icons.clear, size: 24 * textSizeMultiplier),
                onPressed: () {
                  historyProvider.setFilterDate(null);
                },
              ),
          ],
        ),
      ),
      drawer: const AppDrawer(), // Aggiunto il drawer qui
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (historyProvider.filterDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Filtro data: ${_formatDate(historyProvider.filterDate!)}',
                  style: TextStyle(fontSize: 16 * textSizeMultiplier, fontStyle: FontStyle.italic),
                ),
              ),
            Expanded(
              child: historyProvider.filteredHistory.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun elemento nella cronologia.',
                        style: TextStyle(fontSize: 18 * textSizeMultiplier, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: historyProvider.filteredHistory.length,
                      itemBuilder: (context, index) {
                        final entry = historyProvider.filteredHistory[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              '${_formatDate(entry.date)} - ${entry.type}',
                              style: TextStyle(fontSize: 18 * textSizeMultiplier, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              entry.description,
                              style: TextStyle(fontSize: 16 * textSizeMultiplier),
                            ),
                            onTap: () {
                              // Qui potresti aprire una pagina di dettaglio per l'elemento
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Dettaglio: ${entry.description}',
                                    style: TextStyle(fontSize: 14 * textSizeMultiplier),
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 8. PAGINA IMPOSTAZIONI
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Impostazioni',
          style: TextStyle(fontSize: 24 * textSizeMultiplier, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: const AppDrawer(), // Aggiunto il drawer qui
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Dimensione testo
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📏 Dimensione testo: ${(settingsProvider.textSizeMultiplier * 100).toInt()}%',
                      style: TextStyle(fontSize: 18 * textSizeMultiplier, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: settingsProvider.textSizeMultiplier,
                      min: 0.8,
                      max: 1.5,
                      divisions: 7, // 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5
                      label: '${(settingsProvider.textSizeMultiplier * 100).toInt()}%',
                      onChanged: (value) {
                        settingsProvider.setTextSizeMultiplier(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Impostazioni Farmaci
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔔 Farmaci:',
                      style: TextStyle(fontSize: 20 * textSizeMultiplier, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '◦ Ripetizione ogni:',
                          style: TextStyle(fontSize: 18 * textSizeMultiplier),
                        ),
                        DropdownButton<int>(
                          value: settingsProvider.medicationRepetitionDays,
                          items: const [
                            DropdownMenuItem(value: 7, child: Text('7 giorni')),
                            DropdownMenuItem(value: 15, child: Text('15 giorni')),
                            DropdownMenuItem(value: 30, child: Text('30 giorni')),
                            DropdownMenuItem(value: 60, child: Text('60 giorni')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.setMedicationRepetitionDays(value);
                            }
                          },
                          style: TextStyle(
                            fontSize: 18 * textSizeMultiplier,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Switch(
                          value: settingsProvider.medicationRepetitionEnabled,
                          onChanged: (value) {
                            settingsProvider.setMedicationRepetitionEnabled(value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Impostazioni Appuntamenti
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔔 Appuntamenti:',
                      style: TextStyle(fontSize: 20 * textSizeMultiplier, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '◦ Avviso il giorno prima',
                          style: TextStyle(fontSize: 18 * textSizeMultiplier),
                        ),
                        Switch(
                          value: settingsProvider.appointmentDayBeforeReminderEnabled,
                          onChanged: (value) {
                            settingsProvider.setAppointmentDayBeforeReminderEnabled(value);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '◦ Avviso minuti prima',
                          style: TextStyle(
                            fontSize: 18 * textSizeMultiplier,
                            color: settingsProvider.appointmentDayBeforeReminderEnabled
                                ? null
                                : Colors.grey, // Disabilita testo se la dipendenza è spenta
                          ),
                        ),
                        DropdownButton<int>(
                          value: settingsProvider.appointmentMinutesBefore,
                          items: const [
                            DropdownMenuItem(value: 30, child: Text('30 min')),
                            DropdownMenuItem(value: 60, child: Text('60 min')),
                            DropdownMenuItem(value: 90, child: Text('90 min')),
                            DropdownMenuItem(value: 120, child: Text('120 min')),
                          ],
                          onChanged: settingsProvider.appointmentDayBeforeReminderEnabled
                              ? (value) {
                                  if (value != null) {
                                    settingsProvider.setAppointmentMinutesBefore(value);
                                  }
                                }
                              : null, // Disabilita dropdown se la dipendenza è spenta
                          style: TextStyle(
                            fontSize: 18 * textSizeMultiplier,
                            color: settingsProvider.appointmentDayBeforeReminderEnabled
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Colors.grey,
                          ),
                        ),
                        Switch(
                          value: settingsProvider.appointmentMinutesBeforeReminderEnabled,
                          onChanged: settingsProvider.appointmentDayBeforeReminderEnabled
                              ? (value) {
                                  settingsProvider.setAppointmentMinutesBeforeReminderEnabled(value);
                                }
                              : null, // Disabilita switch se la dipendenza è spenta
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Permessi
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permessi:',
                      style: TextStyle(fontSize: 20 * textSizeMultiplier, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '◦ Push Notifications',
                          style: TextStyle(fontSize: 18 * textSizeMultiplier),
                        ),
                        Switch(
                          value: settingsProvider.pushNotificationsEnabled,
                          onChanged: (value) {
                            settingsProvider.setPushNotificationsEnabled(value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Tema
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎨 Tema:',
                      style: TextStyle(fontSize: 20 * textSizeMultiplier, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Modalità:',
                          style: TextStyle(fontSize: 18 * textSizeMultiplier),
                        ),
                        DropdownButton<String>(
                          value: settingsProvider.themeMode,
                          items: const [
                            DropdownMenuItem(value: 'Chiaro', child: Text('Chiaro')),
                            DropdownMenuItem(value: 'Scuro', child: Text('Scuro')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.setThemeMode(value);
                            }
                          },
                          style: TextStyle(
                            fontSize: 18 * textSizeMultiplier,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Simula l'invio di una notifica di prova
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Notifica di prova inviata!',
                            style: TextStyle(fontSize: 14 * textSizeMultiplier),
                          ),
                          backgroundColor: Colors.blue,
                          ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'PROVA NOTIFICA',
                      style: TextStyle(fontSize: 18 * textSizeMultiplier),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await settingsProvider.saveSettings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Impostazioni salvate con successo!',
                            style: TextStyle(fontSize: 14 * textSizeMultiplier),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'SALVA',
                      style: TextStyle(fontSize: 18 * textSizeMultiplier),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Annulla le modifiche ricaricando le impostazioni
                      settingsProvider.dispose(); // Rimuovi il listener temporaneamente
                      settingsProvider.addListener(() {}); // Aggiungi di nuovo il listener
                      settingsProvider._loadSettings(); // Ricarica
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Modifiche annullate.',
                            style: TextStyle(fontSize: 14 * textSizeMultiplier),
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'ANNULLA',
                      style: TextStyle(fontSize: 18 * textSizeMultiplier),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Gestisci Profili
class ManageProfilesPage extends StatefulWidget {
  const ManageProfilesPage({super.key});

  @override
  State<ManageProfilesPage> createState() => _ManageProfilesPageState();
}

class _ManageProfilesPageState extends State<ManageProfilesPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  Profile? _editingProfile;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _addOrUpdateProfile() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nome e numero di telefono non possono essere vuoti.',
            style: TextStyle(fontSize: 14 * Provider.of<SettingsProvider>(context, listen: false).textSizeMultiplier),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (_editingProfile == null) {
      // Aggiungi nuovo profilo
      final newProfile = Profile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        phoneNumber: _phoneController.text,
      );
      profileProvider.addProfile(newProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profilo "${newProfile.name}" aggiunto.',
            style: TextStyle(fontSize: 14 * Provider.of<SettingsProvider>(context, listen: false).textSizeMultiplier),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Aggiorna profilo esistente
      final updatedProfile = _editingProfile!.copyWith(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
      );
      profileProvider.updateProfile(updatedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profilo "${updatedProfile.name}" aggiornato.',
            style: TextStyle(fontSize: 14 * Provider.of<SettingsProvider>(context, listen: false).textSizeMultiplier),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }

    _clearForm();
  }

  void _editProfile(Profile profile) {
    setState(() {
      _editingProfile = profile;
      _nameController.text = profile.name;
      _phoneController.text = profile.phoneNumber;
    });
  }

  void _deleteProfile(String id) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Conferma Eliminazione',
      'Sei sicuro di voler eliminare questo profilo? Questa azione è irreversibile.',
    );
    if (confirmed == true) {
      Provider.of<ProfileProvider>(context, listen: false).deleteProfile(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profilo eliminato.',
            style: TextStyle(fontSize: 14 * Provider.of<SettingsProvider>(context, listen: false).textSizeMultiplier),
          ),
          backgroundColor: Colors.red,
        ),
      );
      _clearForm();
    }
  }

  void _clearForm() {
    setState(() {
      _editingProfile = null;
      _nameController.clear();
      _phoneController.clear();
    });
  }

  /// Mostra un dialog di conferma personalizzato.
  Future<bool?> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: TextStyle(fontSize: 20 * textSizeMultiplier),
          ),
          content: Text(
            content,
            style: TextStyle(fontSize: 16 * textSizeMultiplier),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Annulla',
                style: TextStyle(fontSize: 16 * textSizeMultiplier),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Conferma',
                style: TextStyle(fontSize: 16 * textSizeMultiplier),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final textSizeMultiplier = settingsProvider.textSizeMultiplier;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestisci Profili',
          style: TextStyle(fontSize: 24 * textSizeMultiplier, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: const AppDrawer(), // Aggiunto il drawer qui
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingProfile == null ? 'Aggiungi Nuovo Profilo' : 'Modifica Profilo',
                      style: TextStyle(fontSize: 20 * textSizeMultiplier, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nome Profilo',
                        hintText: 'Es. Mario Rossi',
                        labelStyle: TextStyle(fontSize: 16 * textSizeMultiplier),
                        hintStyle: TextStyle(fontSize: 16 * textSizeMultiplier),
                      ),
                      style: TextStyle(fontSize: 18 * textSizeMultiplier),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Numero di Telefono',
                        hintText: 'Es. 331234567',
                        labelStyle: TextStyle(fontSize: 16 * textSizeMultiplier),
                        hintStyle: TextStyle(fontSize: 16 * textSizeMultiplier),
                      ),
                      style: TextStyle(fontSize: 18 * textSizeMultiplier),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _addOrUpdateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              _editingProfile == null ? 'AGGIUNGI' : 'SALVA MODIFICHE',
                              style: TextStyle(fontSize: 18 * textSizeMultiplier),
                            ),
                          ),
                        ),
                        if (_editingProfile != null) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _clearForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'ANNULLA',
                                style: TextStyle(fontSize: 18 * textSizeMultiplier),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: profileProvider.profiles.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun profilo creato. Aggiungine uno!',
                        style: TextStyle(fontSize: 18 * textSizeMultiplier, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: profileProvider.profiles.length,
                      itemBuilder: (context, index) {
                        final profile = profileProvider.profiles[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: Icon(
                              profile.isDefault ? Icons.star : Icons.person,
                              color: profile.isDefault ? Colors.amber : null,
                              size: 28 * textSizeMultiplier,
                            ),
                            title: Text(
                              profile.name,
                              style: TextStyle(fontSize: 20 * textSizeMultiplier, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Tel: ${profile.phoneNumber} ${profile.authToken != null ? '(Loggato)' : '(Offline)'}',
                              style: TextStyle(fontSize: 16 * textSizeMultiplier),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 24 * textSizeMultiplier),
                                  onPressed: () => _editProfile(profile),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 24 * textSizeMultiplier),
                                  onPressed: () => _deleteProfile(profile.id),
                                ),
                                if (!profile.isDefault)
                                  IconButton(
                                    icon: Icon(Icons.star_border, size: 24 * textSizeMultiplier),
                                    onPressed: () {
                                      profileProvider.selectProfile(profile); // Imposta come default
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Profilo "${profile.name}" impostato come predefinito.',
                                            style: TextStyle(fontSize: 14 * textSizeMultiplier),
                                          ),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            onTap: () {
                              profileProvider.selectProfile(profile);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Profilo "${profile.name}" selezionato.',
                                    style: TextStyle(fontSize: 14 * textSizeMultiplier),
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Estensione per List per trovare il primo elemento o null
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
