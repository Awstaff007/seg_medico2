import 'package:dio/dio.dart';
import 'api_client.dart';
import 'package:segreteria_medica/models/paziente.dart'; // Importa il modello Paziente

class PazienteRepository {
  final Dio _dio;

  PazienteRepository(ApiClient apiClient) : _dio = apiClient.dio;

  // Metodo per recuperare le informazioni del paziente (get_paziente_info)
  Future<Paziente?> getPazienteInfo(String token) async {
    try {
      final response = await _dio.get(
        "info/",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Assumiamo che la risposta contenga i dati del paziente nel formato corretto
        return Paziente.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      _handleError(e, "Recupero info paziente fallito");
      return null;
    } catch (e) {
      print("Errore inatteso durante il recupero info paziente: $e");
      return null;
    }
  }

  // Metodo per recuperare gli appuntamenti attivi (get_appuntamenti_attivi)
  Future<List<dynamic>?> getAppuntamentiAttivi(String token) async {
    try {
      final response = await _dio.get(
        "appuntamenti/",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Assumiamo che la risposta abbia una chiave "appuntamenti" che è una lista
        if (response.data is Map && response.data['appuntamenti'] is List) {
          return response.data['appuntamenti'];
        }
      }
      return null;
    } on DioException catch (e) {
      _handleError(e, "Recupero appuntamenti fallito");
      return null;
    } catch (e) {
      print("Errore inatteso durante il recupero appuntamenti: $e");
      return null;
    }
  }

  // Metodo per ordinare farmaci ripetibili (ordina_farmaci_ripetibili)
  Future<String?> ordinaFarmaciRipetibili(String token, String nomeFarmaco, String numeroTelefono) async {
    try {
      final response = await _dio.post(
        "farmaci/",
        data: {
          "testo": nomeFarmaco,
          "telefono": numeroTelefono,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      if (response.data["success"] == true && response.data["id"] != null) {
        return response.data["id"].toString(); // L'ID potrebbe essere un int, convertiamo in String
      }
      return null;
    } on DioException catch (e) {
      _handleError(e, "Creazione ordine farmaci fallita");
      return null;
    } catch (e) {
      print("Errore inatteso durante la creazione ordine farmaci: $e");
      return null;
    }
  }

  // Metodo per inviare l'ordine farmaci (invia_ordine_farmaci)
  Future<bool> inviaOrdineFarmaci(String token, String orderId, String email, String numeroTelefono) async {
    try {
      final response = await _dio.post(
        "invia/",
        data: {
          "id": orderId,
          "email": email,
          "cellulare": numeroTelefono,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      return response.data["success"] == true;
    } on DioException catch (e) {
      _handleError(e, "Invio ordine farmaci fallito");
      return false;
    } catch (e) {
      print("Errore inatteso durante l'invio ordine farmaci: $e");
      return false;
    }
  }

  // --- Gestione Errori (riutilizza quella di AuthRepository) ---
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