// lib/providers/app\_provider.dart

import 'package:flutter/material.dart';
import 'package:seg\_medico/models/models.dart';
import 'package:seg\_medico/services/api\_service.dart';
import 'package:seg\_medico/services/profile\_manager.dart';
import 'package:flutter\_secure\_storage/flutter\_secure\_storage.dart';

class AppProvider with ChangeNotifier {
final ApiService \_apiService;
final ProfileManager \_profileManager;
final FlutterSecureStorage \_secureStorage = const FlutterSecureStorage();

UserInfo? \_userInfo;
UserInfo? get userInfo =\> \_userInfo;

bool \_isLoggedIn = false;
bool get isLoggedIn =\> \_isLoggedIn;

Profile? \_selectedProfile;
Profile? get selectedProfile =\> \_selectedProfile;

List\<Profile\> \_profiles = [];
List\<Profile\> get profiles =\> \_profiles;

Appointment? \_upcomingAppointment;
Appointment? get upcomingAppointment =\> \_upcomingAppointment;

AppProvider(this.\_apiService, this.\_profileManager) {
\_loadInitialData();
}

Future\<void\> \_loadInitialData() async {
await loadProfiles();
await \_loadSelectedProfile();
await checkLoginStatus();
}

Future\<void\> loadProfiles() async {
\_profiles = await \_profileManager.getProfiles();
notifyListeners();
}

Future\<void\> \_loadSelectedProfile() async {
try {
\_selectedProfile = await \_profileManager.getDefaultProfile();
} catch (e) {
\_selectedProfile = null; // No default profile or not found
}
notifyListeners();
}

Future\<void\> selectProfile(Profile? profile) async {
\_selectedProfile = profile;
if (profile \!= null) {
await \_profileManager.setDefaultProfile(profile.name);
} else {
await \_profileManager.clearDefaultProfile();
}
notifyListeners();
}

Future\<void\> addProfile(Profile profile) async {
await \_profileManager.addProfile(profile);
await loadProfiles();
}

Future\<void\> updateProfile(Profile profile) async {
await \_profileManager.updateProfile(profile);
await loadProfiles();
if (\_selectedProfile?.codFis == profile.codFis) {
\_selectedProfile = profile; // Update selected profile if it was the one edited
}
notifyListeners();
}

Future\<void\> deleteProfile(String codFis) async {
await \_profileManager.deleteProfile(codFis);
await loadProfiles();
if (\_selectedProfile?.codFis == codFis) {
\_selectedProfile = null; // Deselect if the deleted profile was selected
await \_profileManager.clearDefaultProfile();
}
notifyListeners();
}

Future\<bool\> requestOtp(String codFis, String phoneNumber) async {
return await \_apiService.requestOtp(codFis, phoneNumber);
}

Future\<bool\> login(String codFis, String phoneNumber, String otp) async {
try {
final token = await \_apiService.login(codFis, phoneNumber, otp);
if (token \!= null) {
\_isLoggedIn = true;
await \_fetchUserInfoAndAppointments();
notifyListeners();
return true;
}
return false;
} catch (e) {
print('Login error in provider: $e');
return false;
}
}

Future\<void\> logout() async {
await \_apiService.removeToken();
\_isLoggedIn = false;
\_userInfo = null;
\_upcomingAppointment = null;
notifyListeners();
}

Future\<void\> checkLoginStatus() async {
final token = await \_apiService.getToken();
if (token \!= null) {
\_isLoggedIn = true;
await \_fetchUserInfoAndAppointments();
} else {
\_isLoggedIn = false;
\_userInfo = null;
\_upcomingAppointment = null;
}
notifyListeners();
}

Future\<void\> \_fetchUserInfoAndAppointments() async {
\_userInfo = await \_apiService.getUserInfo();
if (\_userInfo \!= null) {
await fetchUpcomingAppointment();
}
notifyListeners();
}

Future\<void\> fetchUpcomingAppointment() async {
if (\_isLoggedIn) {
final appointments = await \_apiService.getAppointments();
if (appointments.isNotEmpty) {
// Find the next upcoming appointment
final now = DateTime.now();
\_upcomingAppointment = appointments.firstWhere(
(app) {
final appDateTime = DateTime.parse('${app.data} ${app.inizio}');
return appDateTime.isAfter(now);
},
orElse: () =\> throw Exception('No upcoming appointments found'),
);
} else {
\_upcomingAppointment = null;
}
} else {
\_upcomingAppointment = null;
}
notifyListeners();
}

Future\<bool\> cancelAppointment(int appointmentId, String phoneNumber) async {
final success = await \_apiService.cancelAppointment(appointmentId, phoneNumber);
if (success) {
await fetchUpcomingAppointment(); // Refresh upcoming appointment
}
return success;
}

Future\<List\<AppointmentSlot\>\> getAppointmentSlots(int ambulatorioId, int numero) async {
return await \_apiService.getAppointmentSlots(ambulatorioId, numero);
}

Future\<bool\> bookAppointment({
required int ambulatorioId,
required int numero,
required String data,
required String inizio,
required String fine,
required String telefono,
String? email,
}) async {
final appointmentId = await \_apiService.bookAppointment(
ambulatorioId: ambulatorioId,
numero: numero,
data: data,
inizio: inizio,
fine: fine,
telefono: telefono,
);
if (appointmentId \!= null) {
final success = await \_apiService.sendConfirmation(
id: appointmentId,
email: email,
cellulare: telefono,
);
if (success) {
await fetchUpcomingAppointment(); // Refresh upcoming appointment
}
return success;
}
return false;
}

Future\<bool\> orderFarmaci(String testoFarmaco, String phoneNumber, String? email) async {
final orderId = await \_apiService.orderFarmaci(testoFarmaco, phoneNumber);
if (orderId \!= null) {
return await \_apiService.sendConfirmation(id: orderId, cellulare: phoneNumber, email: email);
}
return false;
}
}