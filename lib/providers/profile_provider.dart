import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:segreteria_medica/models/paziente.dart';
import 'package:segreteria_medica/models/farmaco.dart';
import 'package:segreteria_medica/main.dart';

class ProfileProvider extends ChangeNotifier {
  Paziente? _activePaziente;
  List<Paziente> _savedProfili = [];
  List<Farmaco> _currentProfileFarmaci = [];
  bool _isLoggedIn = false; // NUOVA PROPRIETÀ

  Paziente? get activePaziente => _activePaziente;
  List<Paziente> get savedProfili => _savedProfili;
  List<Farmaco> get currentProfileFarmaci => _currentProfileFarmaci;
  bool get isLoggedIn => _isLoggedIn; // GETTER PER LA NUOVA PROPRIETÀ

  // SETTER PER LA NUOVA PROPRIETÀ
  set isLoggedIn(bool value) {
    if (_isLoggedIn != value) {
      _isLoggedIn = value;
      notifyListeners();
    }
  }

  ProfileProvider() {
    loadAllData(); // Reso pubblico
  }

  // Carica tutti i dati (profili e farmaci del profilo attivo) - RESO PUBBLICO
  Future<void> loadAllData() async {
    await _loadProfili();
    await _loadFarmaciForActiveProfile();
    notifyListeners();
  }

  // Carica la lista dei profili da SharedPreferences
  Future<void> _loadProfili() async {
    final List<String> profiliJsonStrings = prefs.getStringList('lista_profili_paziente') ?? [];
    final List<Paziente> loadedProfili = [];
    for (String jsonString in profiliJsonStrings) {
      final parts = jsonString.split('|');
      if (parts.length == 4) {
        loadedProfili.add(Paziente(
          nome: parts[0],
          codiceFiscale: parts[1],
          numeroTelefono: parts[2],
          isDefault: parts[3] == 'true',
        ));
      }
    }

    if (loadedProfili.isEmpty) {
      final String? defaultCf = prefs.getString('active_paziente_cf');
      if (defaultCf != null && defaultCf.isNotEmpty) {
        final String? defaultName = prefs.getString('active_paziente_name');
        final String? defaultPhone = prefs.getString('active_paziente_phone');
        if (defaultName != null && defaultPhone != null) {
          loadedProfili.add(Paziente(
            nome: defaultName,
            codiceFiscale: defaultCf,
            numeroTelefono: defaultPhone,
            isDefault: true,
          ));
        }
      }
    }

    _savedProfili = loadedProfili;
    _activePaziente = _savedProfili.firstWhere(
      (p) => p.isDefault,
      orElse: () => _savedProfili.isNotEmpty ? _savedProfili.first : Paziente(nome: '', codiceFiscale: '', numeroTelefono: ''),
    );
  }

  // Salva la lista dei profili in SharedPreferences
  Future<void> _saveProfili() async {
    final List<String> profiliJsonStrings = _savedProfili.map((p) =>
        '${p.nome}|${p.codiceFiscale}|${p.numeroTelefono}|${p.isDefault}'
    ).toList();
    await prefs.setStringList('lista_profili_paziente', profiliJsonStrings);
    // notifyListeners(); // Non notificare qui, loadAllData o i singoli metodi lo faranno
  }

  // Carica i farmaci e il loro stato di selezione per il profilo attivo
  Future<void> _loadFarmaciForActiveProfile() async {
    if (_activePaziente == null || _activePaziente!.codiceFiscale.isEmpty) {
      _currentProfileFarmaci = [];
      return;
    }

    final String farmaciKey = 'farmaci_per_${_activePaziente!.codiceFiscale}';
    final List<String> savedFarmaciData = prefs.getStringList(farmaciKey) ?? [];

    List<Farmaco> loadedFarmaci = [];
    if (savedFarmaciData.isEmpty) {
      loadedFarmaci = [
        Farmaco(nome: 'Tachipirina 1000mg', selezionato: false),
        Farmaco(nome: 'Ibuprofene 600mg', selezionato: false),
        Farmaco(nome: 'Aspirina 100mg', selezionato: false),
        Farmaco(nome: 'Vitamina D', selezionato: false),
      ];
      await saveFarmaciForActiveProfile(loadedFarmaci); // Usa il metodo pubblico
    } else {
      loadedFarmaci = savedFarmaciData.map((data) {
        final parts = data.split('|');
        return Farmaco(nome: parts[0], selezionato: parts[1] == 'true');
      }).toList();
    }
    _currentProfileFarmaci = loadedFarmaci;
  }

  // Salva lo stato attuale dei farmaci per il profilo attivo - RESO PUBBLICO
  Future<void> saveFarmaciForActiveProfile(List<Farmaco> farmaci) async {
    if (_activePaziente == null || _activePaziente!.codiceFiscale.isEmpty) return;

    final String farmaciKey = 'farmaci_per_${_activePaziente!.codiceFiscale}';
    final List<String> farmaciData = farmaci.map((f) => '${f.nome}|${f.selezionato}').toList();
    await prefs.setStringList(farmaciKey, farmaciData);
    // notifyListeners(); // Non notificare qui, i metodi che chiamano questo lo faranno
  }

  // --- Metodi per la Gestione dei Profili ---

  void setActiveProfile(Paziente paziente) {
    if (_activePaziente != null) {
      saveFarmaciForActiveProfile(_currentProfileFarmaci); // Usa il metodo pubblico
    }

    for (var p in _savedProfili) {
      p.isDefault = false;
    }
    paziente.isDefault = true;
    _activePaziente = paziente;

    prefs.setString('active_paziente_name', paziente.nome);
    prefs.setString('active_paziente_cf', paziente.codiceFiscale);
    prefs.setString('active_paziente_phone', paziente.numeroTelefono);

    _saveProfili();
    _loadFarmaciForActiveProfile();
    notifyListeners();
  }

  void addOrUpdateProfile(Paziente newProfile) {
    final existingIndex = _savedProfili.indexWhere((p) => p.codiceFiscale == newProfile.codiceFiscale);

    if (existingIndex != -1) {
      _savedProfili[existingIndex] = newProfile.copyWith(isDefault: _savedProfili[existingIndex].isDefault);
    } else {
      _savedProfili.add(newProfile);
    }
    _saveProfili();
    if (_activePaziente?.codiceFiscale == newProfile.codiceFiscale) {
      _activePaziente = newProfile.copyWith(isDefault: _activePaziente!.isDefault);
      prefs.setString('active_paziente_name', newProfile.nome);
      prefs.setString('active_paziente_cf', newProfile.codiceFiscale);
      prefs.setString('active_paziente_phone', newProfile.numeroTelefono);
    }
    notifyListeners();
  }

  void deleteProfile(Paziente paziente) {
    _savedProfili.removeWhere((p) => p.codiceFiscale == paziente.codiceFiscale);
    if (paziente.isDefault) {
      if (_savedProfili.isNotEmpty) {
        setActiveProfile(_savedProfili.first);
      } else {
        _activePaziente = null;
        prefs.remove('active_paziente_name');
        prefs.remove('active_paziente_cf');
        prefs.remove('active_paziente_phone');
      }
    }
    _saveProfili();
    notifyListeners();
  }

  // --- Metodi per la Gestione dei Farmaci del Profilo Attivo ---

  void updateFarmacoSelection(Farmaco farmaco, bool selected) {
    final index = _currentProfileFarmaci.indexWhere((f) => f.nome == farmaco.nome);
    if (index != -1) {
      _currentProfileFarmaci[index].selezionato = selected;
      saveFarmaciForActiveProfile(_currentProfileFarmaci);
      notifyListeners();
    }
  }

  void addFarmacoToActiveProfile(String nomeFarmaco) {
    if (!_currentProfileFarmaci.any((f) => f.nome.toLowerCase() == nomeFarmaco.toLowerCase())) {
      _currentProfileFarmaci.add(Farmaco(nome: nomeFarmaco, selezionato: false));
      saveFarmaciForActiveProfile(_currentProfileFarmaci);
      notifyListeners();
    }
  }

  void removeFarmacoFromActiveProfile(String nomeFarmaco) {
    _currentProfileFarmaci.removeWhere((f) => f.nome.toLowerCase() == nomeFarmaco.toLowerCase());
    saveFarmaciForActiveProfile(_currentProfileFarmaci);
    notifyListeners();
  }
}