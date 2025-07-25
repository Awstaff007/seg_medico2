// lib/services/api\_service.dart

import 'package:dio/dio.dart';
import 'package:flutter\_secure\_storage/flutter\_secure\_storage.dart';
import '../models/models.dart';

class ApiService {
final Dio \_dio;
final FlutterSecureStorage \_secureStorage = const FlutterSecureStorage();
static const String \_baseUrl = '[https://segreteriamedico.it/api/paziente](https://www.google.com/search?q=https://segreteriamedico.it/api/paziente)';
String? \_token;

ApiService() : \_dio = Dio() {
\_dio.interceptors.add(
InterceptorsWrapper(
onRequest: (options, handler) async {
if (\_token == null) {
\_token = await \_secureStorage.read(key: 'auth\_token');
}
if (\_token \!= null && options.headers['Authorization'] == null) {
options.headers['Authorization'] = \_token;
}
return handler.next(options);
},
onError: (DioException e, handler) async {
// You can add refresh token logic here if the API supports it
// For now, just pass the error
return handler.next(e);
},
),
);
}

// Metodo per impostare il token manualmente (es. dopo il login)
Future\<void\> setToken(String token) async {
\_token = token;
await \_secureStorage.write(key: 'auth\_token', value: token);
}

// Metodo per ottenere il token
Future\<String?\> getToken() async {
\_token ??= await \_secureStorage.read(key: 'auth\_token');
return \_token;
}

// Metodo per rimuovere il token (logout)
Future\<void\> removeToken() async {
\_token = null;
await \_secureStorage.delete(key: 'auth\_token');
}

// Richiesta codice OTP
Future\<bool\> requestOtp(String codFis, String phoneNumber) async {
try {
final response = await \_dio.post(
'$\_baseUrl/otp/',
data: {
'codfis': codFis,
'cellulare': phoneNumber,
},
);
return response.data['success'] ?? false;
} on DioException catch (e) {
print('Errore richiesta OTP: ${e.message}');
return false;
}
}

// Login con codice OTP
Future\<String?\> login(String codFis, String phoneNumber, String otp) async {
try {
final response = await \_dio.post(
'$\_baseUrl/login/',
data: {
'codfis': codFis,
'cellulare': phoneNumber,
'codice': otp,
},
);
if (response.data['token'] \!= null) {
await setToken(response.data['token']);
return response.data['token'];
}
return null;
} on DioException catch (e) {
print('Errore login: ${e.message}');
if (e.response?.statusCode == 400) {
if (e.response?.data['error'] == 'Codice errato') {
throw Exception('Codice errato');
}
if (e.response?.data['error'] == 'Codice scaduto') {
throw Exception('Codice scaduto');
}
}
return null;
}
}

// Ottieni informazioni utente
Future\<UserInfo?\> getUserInfo() async {
try {
final response = await \_dio.get('$\_baseUrl/info/');
return UserInfo.fromJson(response.data);
} on DioException catch (e) {
print('Errore recupero info utente: ${e.message}');
return null;
}
}

// Ottieni slot disponibili per appuntamenti
Future\<List\<AppointmentSlot\>\> getAppointmentSlots(int ambulatorioId, int numero) async {
try {
final response = await \_dio.post(
'$\_baseUrl/slots/',
data: {
'ambulatorio': ambulatorioId,
'numero': numero,
},
);
return (response.data['slots'] as List)
.map((e) =\> AppointmentSlot.fromJson(e))
.toList();
} on DioException catch (e) {
print('Errore recupero slot appuntamenti: ${e.message}');
return [];
}
}

// Prenota un appuntamento
Future\<int?\> bookAppointment({
required int ambulatorioId,
required int numero,
required String data,
required String inizio,
required String fine,
required String telefono,
}) async {
try {
final response = await \_dio.post(
'$\_baseUrl/visita/',
data: {
'ambulatorio': ambulatorioId,
'numero': numero,
'data': data,
'inizio': inizio,
'fine': fine,
'telefono': telefono,
},
);
if (response.data['success'] == true) {
return response.data['id'];
}
return null;
} on DioException catch (e) {
print('Errore prenotazione appuntamento: ${e.message}');
return null;
}
}

// Invia conferma (usato per appuntamenti e farmaci)
Future\<bool\> sendConfirmation({
required int id,
String? email,
required String cellulare,
}) async {
try {
final response = await \_dio.post(
'$\_baseUrl/invia/',
data: {
'id': id,
'email': email,
'cellulare': cellulare,
},
);
return response.data['success'] ?? false;
} on DioException catch (e) {
print('Errore invio conferma: ${e.message}');
return false;
}
}

// Ottieni appuntamenti esistenti
Future\<List\<Appointment\>\> getAppointments() async {
try {
final response = await \_dio.get('$\_baseUrl/appuntamenti/');
return (response.data['appuntamenti'] as List)
.map((e) =\> Appointment.fromJson(e))
.toList();
} on DioException catch (e) {
print('Errore recupero appuntamenti: ${e.message}');
return [];
}
}

// Cancella un appuntamento
Future\<bool\> cancelAppointment(int appointmentId, String phoneNumber) async {
try {
final response = await \_dio.delete(
'$\_baseUrl/appuntamento/$appointmentId/',
queryParameters: {'cellulare': phoneNumber},
);
return response.data['success'] ?? false;
} on DioException catch (e) {
print('Errore cancellazione appuntamento: ${e.message}');
return false;
}
}

// Ordina farmaci
Future\<int?\> orderFarmaci(String testoFarmaco, String phoneNumber) async {
try {
final response = await \_dio.post(
'$\_baseUrl/farmaci/',
data: {
'testo': testoFarmaco,
'telefono': phoneNumber,
},
);
if (response.data['success'] == true) {
return response.data['id'];
}
return null;
} on DioException catch (e) {
print('Errore ordine farmaci: ${e.message}');
return null;
}
}
}