// lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import 'package:seg_medico/models/profilo.dart';
import 'package:seg_medico/services/api_service.dart'; // Importa il nuovo ApiService
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Per jsonEncode e jsonDecode

class AppProvider extends ChangeNotifier {
  // Servizio API
  final ApiService _apiService = ApiService();

  // Stato del tema e dimensione testo
  ThemeMode _themeMode = ThemeMode.system;
  double _textScaleFactor = 1.0;

  // Stato di autenticazione e profilo
  String? _authToken; // Token di autenticazione
  Profilo? _currentProfile; // Profilo dell'utente loggato (quello autenticato)
  Profilo? _selectedProfile; // Il profilo selezionato dal dropdown (non necessariamente autenticato)

  // Gestione profili locali (non legati all'API)
  List<Profilo> _localProfiles = [];

  // Dati utente (se loggato)
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _history = [];

  // Impostazioni notifiche
  int _medicationReminderDays = 30;
  bool _medicationReminderEnabled = false;
  bool _appointmentDayBeforeEnabled = false;
  int _appointmentMinutesBeforeValue = 30; // 30, 60, 90, 120
  bool _appointmentMinutesBeforeEnabled = false;

  // Messaggi di errore
  String? _errorMessage;

  // Costruttore: carica le impostazioni e i profili all'avvio
  AppProvider() {
    _loadSettings();
    _loadAuthToken();
    _loadCurrentProfile();
    _loadLocalProfiles(); // Carica i profili salvati localmente
  }

  // --- Getters ---
  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  String? get authToken => _authToken;
  Profilo? get currentProfile => _currentProfile;
  Profilo? get selectedProfile => _selectedProfile;
  List<Profilo> get localProfiles => _localProfiles; // Getter corretto
  bool get isLoggedIn => _authToken != null && _currentProfile != null;
  List<Map<String, dynamic>> get appointments => _appointments;
  List<Map<String, dynamic>> get medications => _medications;
  List<Map<String, dynamic>> get history => _history;
  String? get errorMessage => _errorMessage;

  int get medicationReminderDays => _medicationReminderDays;
  bool get medicationReminderEnabled => _medicationReminderEnabled;
  bool get appointmentDayBeforeEnabled => _appointmentDayBeforeEnabled;
  int get appointmentMinutesBeforeValue => _appointmentMinutesBeforeValue;
  bool get appointmentMinutesBeforeEnabled => _appointmentMinutesBeforeEnabled;

  // Temi (senza 'const' per permettere BorderRadius.circular)
  ThemeData get lightThemeData => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      );

  ThemeData get darkThemeData => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color.fromARGB(255, 60, 60, 60),
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      );

  // --- Methods for Settings ---
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  void setTextScaleFactor(double scale) {
    _textScaleFactor = scale;
    _saveSettings();
    notifyListeners();
  }

  void setMedicationReminderDays(int days) {
    _medicationReminderDays = days;
    _saveSettings();
    notifyListeners();
  }

  void toggleMedicationReminder(bool enabled) {
    _medicationReminderEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }

  void toggleAppointmentDayBefore(bool enabled) {
    _appointmentDayBeforeEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }

  void setAppointmentMinutesBeforeValue(int minutes) {
    _appointmentMinutesBeforeValue = minutes;
    _saveSettings();
    notifyListeners();
  }

  void toggleAppointmentMinutesBefore(bool enabled) {
    _appointmentMinutesBeforeEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }

  // --- Persistence Methods (SharedPreferences) ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getBool('isDarkMode') == true ? ThemeMode.dark : ThemeMode.light;
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    _medicationReminderDays = prefs.getInt('medicationReminderDays') ?? 30;
    _medicationReminderEnabled = prefs.getBool('medicationReminderEnabled') ?? false;
    _appointmentDayBeforeEnabled = prefs.getBool('appointmentDayBeforeEnabled') ?? false;
    _appointmentMinutesBeforeValue = prefs.getInt('appointmentMinutesBeforeValue') ?? 30;
    _appointmentMinutesBeforeEnabled = prefs.getBool('appointmentMinutesBeforeEnabled') ?? false;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    await prefs.setDouble('textScaleFactor', _textScaleFactor);
    await prefs.setInt('medicationReminderDays', _medicationReminderDays);
    await prefs.setBool('medicationReminderEnabled', _medicationReminderEnabled);
    await prefs.setBool('appointmentDayBeforeEnabled', _appointmentDayBeforeEnabled);
    await prefs.setInt('appointmentMinutesBeforeValue', _appointmentMinutesBeforeValue);
    await prefs.setBool('appointmentMinutesBeforeEnabled', _appointmentMinutesBeforeEnabled);
  }

  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    notifyListeners();
  }

  Future<void> _saveCurrentProfile(Profilo profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentProfile', profile.toJson());
  }

  Future<void> _loadCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('currentProfile');
    if (profileJson != null) {
      _currentProfile = Profilo.fromJson(profileJson);
      // Se c'è un profilo corrente loggato, selezionalo automaticamente
      _selectedProfile = _currentProfile;
      // Carica i dati associati al profilo loggato
      await _fetchUserData();
    }
    notifyListeners();
  }

  Future<void> _saveLocalProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> profilesJson = _localProfiles.map((p) => p.toJson()).toList();
    await prefs.setStringList('localProfiles', profilesJson);
  }

  Future<void> _loadLocalProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? profilesJson = prefs.getStringList('localProfiles');
    if (profilesJson != null) {
      _localProfiles = profilesJson.map((json) => Profilo.fromJson(json)).toList();
    } else {
      // Se non ci sono profili salvati, crea un profilo di esempio
      _localProfiles = [
        // CORREZIONE: Aggiunto codiceFiscale alle istanze di Profilo
        Profilo(id: '1', nome: 'Mario', cognome: 'Rossi', cellulare: '3331234567', codiceFiscale: 'MRXYSN...'),
        Profilo(id: '2', nome: 'Luisa', cognome: 'Bianchi', cellulare: '3398765432', codiceFiscale: 'LSABNC...'),
      ];
      await _saveLocalProfiles(); // Salva i profili di esempio
    }
    // Se non c'è un profilo selezionato e ci sono profili locali, seleziona il primo
    if (_selectedProfile == null && _localProfiles.isNotEmpty) {
      _selectedProfile = _localProfiles.first;
    }
    notifyListeners();
  }

  // --- Profile Management (Offline) ---
  void addProfile(Profilo profile) {
    // Genera un ID semplice per i profili locali se non ne hanno uno
    final newProfile = profile.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    _localProfiles.add(newProfile);
    _saveLocalProfiles();
    notifyListeners();
  }

  void updateProfile(Profilo oldProfile, Profilo newProfile) {
    final index = _localProfiles.indexWhere((p) => p.id == oldProfile.id);
    if (index != -1) {
      _localProfiles[index] = newProfile;
      _saveLocalProfiles();
      // Se il profilo aggiornato è quello selezionato o corrente, aggiorna anche loro
      if (_selectedProfile?.id == oldProfile.id) {
        _selectedProfile = newProfile;
      }
      if (_currentProfile?.id == oldProfile.id) {
        _currentProfile = newProfile;
      }
      notifyListeners();
    }
  }

  void deleteProfile(Profilo profile) {
    _localProfiles.removeWhere((p) => p.id == profile.id);
    _saveLocalProfiles();
    // Se il profilo eliminato era quello selezionato o corrente, deselezionalo/disconnetti
    if (_selectedProfile?.id == profile.id) {
      _selectedProfile = null;
    }
    if (_currentProfile?.id == profile.id) {
      logout(); // Forse è meglio fare il logout se elimini il profilo corrente
    }
    notifyListeners();
  }

  void selectProfile(Profilo? profile) {
    _selectedProfile = profile;
    notifyListeners();
  }

  // --- Authentication and Data Fetching ---
  Future<bool> requestOtp(String codFis, String cellulare) async {
    _errorMessage = null;
    notifyListeners();
    bool success = await _apiService.requestOtp(codFis, cellulare);
    if (!success) {
      _errorMessage = 'Errore nell\'invio dell\'OTP o limite di richieste raggiunto.';
    }
    notifyListeners();
    return success;
  }

  Future<bool> performLogin(String codFis, String cellulare, String otpCode) async {
    _errorMessage = null;
    notifyListeners();
    String? token = await _apiService.login(codFis, cellulare, otpCode);
    if (token != null) {
      // Usa il metodo consolidato per impostare token e profilo
      PatientInfo? patientInfo = await _apiService.getPatientInfo(token);
      if (patientInfo != null) {
        // CORREZIONE: Chiamata corretta al metodo consolidato
        setAuthTokenAndCurrentProfile(token, patientInfo.paziente);
        return true;
      } else {
        _errorMessage = 'Impossibile recuperare le informazioni del paziente.';
        await logout(); // Logout se non si recuperano le info
        return false;
      }
    } else {
      _errorMessage = 'Login fallito. Codice OTP errato o dati non validi.';
      notifyListeners();
      return false;
    }
  }

  // Metodo per impostare il token e il profilo corrente dopo un login riuscito
  void setAuthTokenAndCurrentProfile(String token, Profilo profile) {
    _authToken = token;
    _currentProfile = profile;
    _saveAuthToken(token);
    _saveCurrentProfile(profile);
    _selectedProfile = profile; // Assicura che il profilo selezionato sia quello loggato
    notifyListeners();
    _fetchUserData(); // Carica i dati utente
  }

  // Metodo per il logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('currentProfile');
    _authToken = null;
    _currentProfile = null;
    _appointments = []; // Pulisci i dati utente
    _medications = [];
    _history = [];
    _errorMessage = null;
    // Se il profilo selezionato era quello loggato, deselezionalo
    if (_selectedProfile?.id == _currentProfile?.id) {
      _selectedProfile = null;
    }
    notifyListeners();
  }

  // Metodo per caricare tutti i dati dell'utente loggato (appuntamenti, farmaci, cronologia)
  Future<void> _fetchUserData() async {
    if (_currentProfile != null && _authToken != null) {
      _appointments = await _apiService.getAppointmentsForProfile(_currentProfile!.id);
      _medications = await _apiService.getMedicationsForProfile(_currentProfile!.id);
      _history = await _apiService.getHistoryForProfile(_currentProfile!.id);
    } else {
      _appointments = [];
      _medications = [];
      _history = [];
    }
    notifyListeners();
  }

  // Metodi per interagire con i dati (chiamano ApiService)
  Future<bool> cancelAppointment(String appointmentId) async {
    if (_currentProfile == null) {
      _errorMessage = 'Nessun profilo loggato per annullare l\'appuntamento.';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    notifyListeners();
    bool success = await _apiService.cancelAppointment(appointmentId, _currentProfile!.id);
    if (success) {
      _appointments.removeWhere((app) => app['id'] == appointmentId);
      notifyListeners();
    } else {
      _errorMessage = 'Errore durante l\'annullamento dell\'appuntamento.';
      notifyListeners();
    }
    return success;
  }

  Future<List<Map<String, dynamic>>> getAppointmentAvailability() async {
    return await _apiService.getAppointmentAvailability();
  }

  Future<bool> bookAppointment(Map<String, dynamic> appointmentDetails) async {
    if (_currentProfile == null) {
      _errorMessage = 'Nessun profilo loggato per prenotare l\'appuntamento.';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    notifyListeners();
    bool success = await _apiService.bookAppointment(_currentProfile!.id, appointmentDetails);
    if (success) {
      await _fetchUserData(); // Ricarica gli appuntamenti dopo la prenotazione
    } else {
      _errorMessage = 'Errore durante la prenotazione dell\'appuntamento.';
      notifyListeners();
    }
    return success;
  }

  Future<bool> orderMedications(List<String> medicationIds) async {
    if (_currentProfile == null) {
      _errorMessage = 'Nessun profilo loggato per ordinare i farmaci.';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    notifyListeners();
    bool success = await _apiService.orderMedications(_currentProfile!.id, medicationIds);
    if (!success) {
      _errorMessage = 'Errore durante l\'invio dell\'ordine farmaci.';
      notifyListeners();
    }
    return success;
  }
}
