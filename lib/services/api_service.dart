import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:seg_medico/models/models.dart';

class ApiService {
  final String _baseUrl = "https://api.example.com"; // Sostituisci con il tuo URL base
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // --- Autenticazione ---

  Future<void> requestSmsCode(String phone) async {
    print("API: Richiesta codice SMS per $phone");
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<String> verifySmsCode(String phone, String code) async {
    print("API: Verifica codice $code per $phone");
    await Future.delayed(const Duration(seconds: 1));
    if (code == "123456") {
      return "fake-jwt-token-for-$phone";
    } else {
      throw Exception("Codice errato o scaduto");
    }
  }

  Future<void> logout() async {
      print("API: Logout");
      await Future.delayed(const Duration(milliseconds: 500));
      clearAuthToken();
  }

  // --- Appuntamenti ---

  Future<List<Appointment>> getAppointments() async {
      await Future.delayed(const Duration(milliseconds: 800));
      return [
          Appointment(id: 'appt1', date: DateTime(2025, 7, 28, 14, 00), notes: 'Chiedere dosaggio nuovo farmaco'),
          Appointment(id: 'appt2', date: DateTime(2025, 8, 15, 10, 30), notes: 'Controllo pressione'),
      ];
  }

  Future<List<AppointmentSlot>> getAppointmentSlots(String ambulatorioId, String numero) async {
    print("API: Richiesta slot per $ambulatorioId, numero $numero");
    await Future.delayed(const Duration(seconds: 1));
    return [
      AppointmentSlot(id: "slot1", date: DateTime(2025, 7, 28), startTime: const TimeOfDay(hour: 10, minute: 0)),
      AppointmentSlot(id: "slot2", date: DateTime(2025, 7, 29), startTime: const TimeOfDay(hour: 14, minute: 0)),
      AppointmentSlot(id: "slot3", date: DateTime(2025, 7, 29), startTime: const TimeOfDay(hour: 14, minute: 30)),
      AppointmentSlot(id: "slot4", date: DateTime(2025, 7, 30), startTime: const TimeOfDay(hour: 9, minute: 30)),
    ];
  }

  Future<void> bookAppointment(AppointmentSlot slot, String notes) async {
    print("API: Prenotazione slot ${slot.id} in data ${slot.date} alle ${slot.startTime} con note '$notes'");
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> cancelAppointment(String appointmentId) async {
    print("API: Cancellazione appuntamento $appointmentId");
    await Future.delayed(const Duration(seconds: 1));
  }

  // --- Farmaci ---
  
  Future<List<Drug>> getDrugs() async {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        Drug(id: '1', name: 'Paracetamolo 1000mg'),
        Drug(id: '2', name: 'Cardioaspirina'),
        Drug(id: '3', name: 'Integratore Vitamina D'),
        Drug(id: '4', name: 'Lasix 25mg'),
      ];
  }

  Future<void> orderDrugs(List<String> drugIds, String notes, String profileId) async {
    print("API: Ordine farmaci $drugIds con note '$notes' per profilo $profileId");
    await Future.delayed(const Duration(seconds: 2));
  }
  
  // --- Cronologia ---
  Future<List<HistoryEntry>> getHistory() async {
      await Future.delayed(const Duration(seconds: 1));
      return [
        HistoryEntry(date: DateTime(2025, 7, 15), type: 'Farmaco', description: 'Ordine: Paracetamolo – febbre persistente'),
        HistoryEntry(date: DateTime(2025, 7, 8), type: 'Farmaco', description: 'Ordine: Aspirina – dosaggio aumentato'),
        HistoryEntry(date: DateTime(2025, 6, 22), type: 'Appuntamento', description: 'Visita dermatologica – controllo nevi'),
        HistoryEntry(date: DateTime(2025, 5, 10), type: 'Appuntamento', description: 'Cancellata: Visita di controllo'),
      ];
  }
}
