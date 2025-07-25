// lib/services/api_service.dart
import 'package:dio/dio.dart'; // Importa Dio
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seg_medico/models/models.dart'; // Assicurati che questo path sia corretto

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _baseUrl = 'https://segreteriamedico.it/api/paziente'; // URL corretto, senza backslash e link
  String? _token;

  ApiService() : _dio = Dio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token == null) {
            _token = await _secureStorage.read(key: 'auth_token');
          }
          if (_token != null && options.headers['Authorization'] == null) {
            options.headers['Authorization'] = 'Bearer $_token'; // Usa Bearer token
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async { // Usa DioException
          if (e.response?.statusCode == 401) {
            // Token scaduto o non valido, prova a rinfrescarlo o a sloggare
            await removeToken();
            // Potresti voler reindirizzare alla schermata di login qui
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    if (_token == null) {
      _token = await _secureStorage.read(key: 'auth_token');
    }
    return _token;
  }

  Future<void> removeToken() async {
    _token = null;
    await _secureStorage.delete(key: 'auth_token');
  }

  Future<bool> requestOtp(String codFis, String phoneNumber) async {
    try {
      final response = await _dio.post(
        '${_baseUrl}/otp/', // Corretto l'interpolazione
        data: {'cod_fis': codFis, 'phone_number': phoneNumber},
      );
      return response.statusCode == 200;
    } on DioException catch (e) { // Usa DioException
      print('OTP Request Error: $e');
      return false;
    }
  }

  Future<String?> login(String codFis, String phoneNumber, String otp) async {
    try {
      final response = await _dio.post(
        '${_baseUrl}/login/', // Corretto l'interpolazione
        data: {
          'cod_fis': codFis,
          'phone_number': phoneNumber,
          'otp': otp,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'];
        if (token != null) {
          await setToken(token);
          return token;
        }
      }
      return null;
    } on DioException catch (e) { // Usa DioException
      print('Login Error: $e');
      return null;
    }
  }

  Future<UserInfo?> getUserInfo() async {
    try {
      final response = await _dio.get('${_baseUrl}/info/'); // Corretto l'interpolazione
      if (response.statusCode == 200 && response.data != null) {
        return UserInfo.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) { // Usa DioException
      print('Get User Info Error: $e');
      return null;
    }
  }

  Future<List<AppointmentSlot>> getAppointmentSlots(int ambulatorioId, int numero) async {
    try {
      final response = await _dio.get(
        '${_baseUrl}/slots/', // Corretto l'interpolazione
        queryParameters: {
          'ambulatorio_id': ambulatorioId,
          'numero': numero,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List)
            .map((e) => AppointmentSlot.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) { // Usa DioException
      print('Get Appointment Slots Error: $e');
      return [];
    }
  }

  Future<int?> bookAppointment({
    required int ambulatorioId,
    required int numero,
    required String data,
    required String inizio,
    required String fine,
    required String telefono,
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        '${_baseUrl}/visita/', // Corretto l'interpolazione
        data: {
          'ambulatorio_id': ambulatorioId,
          'numero': numero,
          'data': data,
          'inizio': inizio,
          'fine': fine,
          'telefono': telefono,
          'email': email,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['id']; // Assumendo che l'API ritorni un ID
      }
      return null;
    } on DioException catch (e) { // Usa DioException
      print('Book Appointment Error: $e');
      return null;
    }
  }

  Future<bool> sendConfirmation({
    required int id,
    String? cellulare,
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        '${_baseUrl}/invia/', // Corretto l'interpolazione
        data: {
          'id': id,
          'cellulare': cellulare,
          'email': email,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) { // Usa DioException
      print('Send Confirmation Error: $e');
      return false;
    }
  }

  Future<List<Appointment>> getAppointments() async {
    try {
      final response = await _dio.get('${_baseUrl}/appuntamenti/'); // Corretto l'interpolazione
      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List)
            .map((e) => Appointment.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) { // Usa DioException
      print('Get Appointments Error: $e');
      return [];
    }
  }

  Future<bool> cancelAppointment(int appointmentId, String phoneNumber) async {
    try {
      final response = await _dio.delete(
        '${_baseUrl}/appuntamento/$appointmentId/', // Corretto l'interpolazione
        data: {'phone_number': phoneNumber},
      );
      return response.statusCode == 200;
    } on DioException catch (e) { // Usa DioException
      print('Cancel Appointment Error: $e');
      return false;
    }
  }

  Future<int?> orderFarmaci(String testoFarmaco, String phoneNumber) async {
    try {
      final response = await _dio.post(
        '${_baseUrl}/farmaci/', // Corretto l'interpolazione
        data: {
          'testo_farmaco': testoFarmaco,
          'phone_number': phoneNumber,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['id']; // Assumendo che l'API ritorni un ID
      }
      return null;
    } on DioException catch (e) { // Usa DioException
      print('Order Farmaci Error: $e');
      return null;
    }
  }
}