import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:segreteria_medica/main.dart'; // Per accedere a prefs globali

class SettingsProvider extends ChangeNotifier {
  double _fontSizeScale = 1.0; // Scala di default (1.0 = dimensione normale)
  String _courtesyPhrase = "Spett.le dott. [NomeDottore], ecco la lista di medicinali che voglio ordinare:"; // Frase di cortesia di default

  double get fontSizeScale => _fontSizeScale;
  String get courtesyPhrase => _courtesyPhrase;

  SettingsProvider() {
    _loadSettings(); // Carica le impostazioni all'inizializzazione
  }

  // Carica le impostazioni da SharedPreferences
  Future<void> _loadSettings() async {
    _fontSizeScale = prefs.getDouble('fontSizeScale') ?? 1.0;
    _courtesyPhrase = prefs.getString('courtesyPhrase') ?? "Spett.le dott. [NomeDottore], ecco la lista di medicinali che voglio ordinare:";
    notifyListeners(); // Notifica i listener che i dati sono stati caricati
  }

  // Imposta la scala della dimensione dei caratteri
  Future<void> setFontSizeScale(double scale) async {
    if (scale != _fontSizeScale) {
      _fontSizeScale = scale;
      await prefs.setDouble('fontSizeScale', scale);
      notifyListeners(); // Notifica i widget che la dimensione è cambiata
    }
  }

  // Imposta la frase di cortesia
  Future<void> setCourtesyPhrase(String phrase) async {
    if (phrase != _courtesyPhrase) {
      _courtesyPhrase = phrase;
      await prefs.setString('courtesyPhrase', phrase);
      notifyListeners(); // Notifica i widget che la frase è cambiata
    }
  }
}