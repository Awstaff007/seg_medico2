import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: "https://segreteriamedico.it/api/paziente/", // L'URL base delle tue API
    headers: {
      "User-Agent": "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36", // User-Agent da dispositivo mobile
      "Accept": "application/json, text/plain, */*",
      "Content-Type": "application/json",
      "Referer": "https://segreteriamedico.it/client/",
      "Origin": "https://segreteriamedico.it",
    },
    connectTimeout: const Duration(seconds: 10), // Timeout per la connessione
    receiveTimeout: const Duration(seconds: 10), // Timeout per la ricezione dati
  )) {
    // Opzionale: Aggiungi un intercettore per il log delle richieste/risposte (utile per il debug)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Dio get dio => _dio; // Getter per accedere all'istanza di Dio
}