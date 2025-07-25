import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart'; // Importiamo il nostro ApiClient

class AuthRepository {
  final Dio _dio;
  final SharedPreferences _prefs; // Per salvare il token localmente

  // Costruttore che richiede un'istanza di Dio e SharedPreferences
  AuthRepository(ApiClient apiClient, this._prefs) : _dio = apiClient.dio;

  // Chiave per salvare il token nelle preferenze condivise
  static const String _authTokenKey = 'auth_token';
  static const String _activePazienteCfKey = 'active_paziente_cf';
  static const String _activePazientePhoneKey = 'active_paziente_phone';
  static const String _activePazienteNameKey = 'active_paziente_name';


  // --- Metodi per l'Autenticazione ---

  Future<bool> richiestaOtp(String codiceFiscale, String numeroTelefono) async {
    try {
      final response = await _dio.post(
        "otp/",
        data: {
          "codfis": codiceFiscale,
          "cellulare": numeroTelefono,
        },
      );
      // Controlliamo la risposta come nel tuo script Python
      return response.data["success"] == true;
    } on DioException catch (e) {
      _handleError(e, "Richiesta OTP fallita");
      return false;
    } catch (e) {
      print("Errore inatteso durante la richiesta OTP: $e");
      return false;
    }
  }

  Future<String?> loginConOtp(String codiceFiscale, String numeroTelefono, String otpCode) async {
    try {
      final response = await _dio.post(
        "login/",
        data: {
          "codfis": codiceFiscale,
          "cellulare": numeroTelefono,
          "codice": otpCode,
        },
      );

      if (response.data["token"] != null && response.data["token"].isNotEmpty) {
        final String token = response.data["token"];
        await _saveAuthToken(token); // Salva il token
        // Salva anche i dettagli del paziente attivo (CF e telefono)
        await _prefs.setString(_activePazienteCfKey, codiceFiscale);
        await _prefs.setString(_activePazientePhoneKey, numeroTelefono);
        // Nome paziente sarà recuperato dopo con getPazienteInfo

        return token;
      } else {
        print("Login fallito: Token non ricevuto.");
        return null;
      }
    } on DioException catch (e) {
      _handleError(e, "Login OTP fallito");
      return null;
    } catch (e) {
      print("Errore inatteso durante il login: $e");
      return null;
    }
  }

  Future<void> logout() async {
    // Cancella il token e i dati del paziente attivo
    await _prefs.remove(_authTokenKey);
    await _prefs.remove(_activePazienteCfKey);
    await _prefs.remove(_activePazientePhoneKey);
    await _prefs.remove(_activePazienteNameKey);
    print("Utente disconnesso. Token e dati cancellati.");
  }

  // --- Metodi per la Gestione del Token ---

  Future<String?> getAuthToken() async {
    return _prefs.getString(_authTokenKey);
  }

  Future<void> _saveAuthToken(String token) async {
    await _prefs.setString(_authTokenKey, token);
  }

  // --- Metodi per la Gestione del Paziente Attivo ---
  Future<Map<String, String?>> getActivePazienteCredentials() async {
    return {
      'codiceFiscale': _prefs.getString(_activePazienteCfKey),
      'numeroTelefono': _prefs.getString(_activePazientePhoneKey),
      'nome': _prefs.getString(_activePazienteNameKey),
    };
  }

  Future<void> setActivePazienteInfo(String nome, String cf, String phone) async {
    await _prefs.setString(_activePazienteNameKey, nome);
    await _prefs.setString(_activePazienteCfKey, cf);
    await _prefs.setString(_activePazientePhoneKey, phone);
  }

  // --- Gestione Errori (simile al tuo Python) ---
  void _handleError(DioException e, String message) {
    if (e.response != null) {
      print("$message - Errore HTTP: ${e.response!.statusCode} - ${e.response!.statusMessage}");
      if (e.response!.data is Map) {
        final errorMessage = e.response!.data["message"] ?? "Dettagli errore non specificati.";
        print("Dettagli dal server: $errorMessage");
      } else {
        print("Risposta errore non JSON: ${e.response!.data}");
      }
    } else {
      print("$message - Errore di rete: ${e.message}");
    }
  }
}