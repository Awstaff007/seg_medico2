import 'package:flutter/material.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/services/api_service.dart';
import 'package:seg_medico/utils/profile_manager.dart';
import 'dart:async';

class AppProvider with ChangeNotifier {
  final ApiService _apiService;
  final ProfileManager _profileManager;

  // State
  Profile? _currentProfile;
  bool _isLoggedIn = false;
  String? _authToken;
  Appointment? _nextAppointment;
  List<AppointmentSlot> _availableSlots = [];
  List<Drug> _userDrugs = [];
  List<HistoryEntry> _history = [];
  Settings _settings = Settings();
  bool _isLoading = false;
  String? _errorMessage;
  double _fontSizeMultiplier = 1.0;

  // Getters
  Profile? get currentProfile => _currentProfile;
  bool get isLoggedIn => _isLoggedIn;
  Appointment? get nextAppointment => _nextAppointment;
  List<AppointmentSlot> get availableSlots => _availableSlots;
  List<Drug> get userDrugs => _userDrugs;
  List<HistoryEntry> get history => _history;
  Settings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get fontSizeMultiplier => _fontSizeMultiplier;

  AppProvider(this._apiService, this._profileManager) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _settings = await _profileManager.loadSettings();
    _fontSizeMultiplier = _settings.fontSize / 100.0;
    await _loadProfileData();
    notifyListeners();
  }

  Future<void> _loadProfileData() async {
    _currentProfile = await _profileManager.getDefaultProfile();
    if (_currentProfile != null) {
      _authToken = await _profileManager.getToken(_currentProfile!.id);
      if (_authToken != null && _authToken!.isNotEmpty) {
        _isLoggedIn = true;
        _apiService.setAuthToken(_authToken!);
        await fetchAllDataForProfile();
      } else {
        _isLoggedIn = false;
        _cleanProfileData();
      }
    }
    notifyListeners();
  }
  
  void _cleanProfileData() {
      _nextAppointment = null;
      _userDrugs = [];
      _history = [];
  }

  Future<void> fetchAllDataForProfile() async {
    if (!_isLoggedIn || _currentProfile == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        fetchNextAppointment(),
        fetchUserDrugs(),
        fetchHistory(),
      ]);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Errore nel caricamento dei dati: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestLoginSms() async {
    if (_currentProfile == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.requestSmsCode(_currentProfile!.phone);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String code) async {
    if (_currentProfile == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _apiService.verifySmsCode(_currentProfile!.phone, code);
      await _profileManager.saveToken(_currentProfile!.id, token);
      _authToken = token;
      _isLoggedIn = true;
      _apiService.setAuthToken(token);
      await fetchAllDataForProfile();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoggedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_currentProfile != null) {
      await _apiService.logout();
      await _profileManager.deleteToken(_currentProfile!.id);
    }
    _isLoggedIn = false;
    _authToken = null;
    _apiService.clearAuthToken();
    _cleanProfileData();
    notifyListeners();
  }

  Future<void> switchProfile(String profileId) async {
    final profile = await _profileManager.getProfile(profileId);
    if (profile != null) {
      await _profileManager.setDefaultProfile(profileId);
      await _loadProfileData(); 
    }
  }
  
  List<Profile> getProfiles() {
    return _profileManager.getProfiles();
  }

  Future<void> addProfile(Profile profile) async {
    await _profileManager.saveProfile(profile);
    await _loadProfileData();
  }

  Future<void> deleteProfile(String profileId) async {
    await _profileManager.deleteProfile(profileId);
    await _loadProfileData();
  }


  // Appointments
  Future<void> fetchNextAppointment() async {
    if (!_isLoggedIn || _currentProfile == null) return;
    try {
      final appointments = await _apiService.getAppointments();
      final upcoming = appointments.where((a) => a.date.isAfter(DateTime.now())).toList();
      if(upcoming.isNotEmpty){
        upcoming.sort((a,b) => a.date.compareTo(b.date));
        _nextAppointment = upcoming.first;
      } else {
        _nextAppointment = null;
      }
    } catch (e) {
      _errorMessage = "Impossibile caricare il prossimo appuntamento.";
    }
    notifyListeners();
  }

  Future<void> fetchAvailableSlots() async {
    if (!_isLoggedIn || _currentProfile == null) return;
    _isLoading = true;
    _availableSlots = [];
    notifyListeners();
    try {
      _availableSlots = await _apiService.getAppointmentSlots("AMB01", "12345");
    } catch (e) {
      _errorMessage = "Impossibile caricare le disponibilità.";
      _availableSlots = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> bookAppointment(AppointmentSlot slot, String notes) async {
    if (!_isLoggedIn) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.bookAppointment(slot, notes);
      await fetchNextAppointment(); // Refresh appointments
      return true;
    } catch (e) {
      _errorMessage = "Errore durante la prenotazione: ${e.toString()}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    if (!_isLoggedIn) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.cancelAppointment(appointmentId);
      await fetchNextAppointment(); // Cerca il prossimo disponibile
      await fetchHistory(); // Refresh history
    } catch (e) {
      _errorMessage = "Errore durante la cancellazione: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Drugs
  Future<void> fetchUserDrugs() async {
    if (!_isLoggedIn || _currentProfile == null) return;
    _userDrugs = await _apiService.getDrugs();
    notifyListeners();
  }

  Future<bool> orderDrugs(List<String> drugIds, String notes) async {
     if (!_isLoggedIn || currentProfile == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
        await _apiService.orderDrugs(drugIds, notes, currentProfile!.id);
        await fetchHistory();
        return true;
    } catch (e) {
        _errorMessage = "Errore durante l'ordine: ${e.toString()}";
        return false;
    } finally {
        _isLoading = false;
        notifyListeners();
    }
  }

  // History
  Future<void> fetchHistory() async {
    if (!_isLoggedIn) return;
    _history = await _apiService.getHistory();
    _history.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  // Settings
  Future<void> updateSettings(Settings newSettings) async {
    _settings = newSettings;
    _fontSizeMultiplier = _settings.fontSize / 100.0;
    await _profileManager.saveSettings(_settings);
    notifyListeners();
  }
  
  void updateFontSize(double percentage) {
      if (percentage >= 50 && percentage <= 200) {
          _settings.fontSize = percentage;
          _fontSizeMultiplier = percentage / 100.0;
          notifyListeners();
      }
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
