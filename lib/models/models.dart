import 'package:flutter/material.dart';


class Profile {
  final String id;
  final String name;
  final String codFis;
  final String phone;
  final String? email;

  Profile({required this.id, required this.name, required this.codFis, required this.phone, this.email});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      codFis: json['codFis'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'codFis': codFis,
      'phone': phone,
      'email': email,
    };
  }
}

class Appointment {
  final String id;
  final DateTime date;
  final String notes;

  Appointment({required this.id, required this.date, required this.notes});
}

class AppointmentSlot {
  final String id;
  final DateTime date;
  final TimeOfDay startTime;

  AppointmentSlot({required this.id, required this.date, required this.startTime});
}

class Drug {
  final String id;
  final String name;
  bool isSelected;

  Drug({required this.id, required this.name, this.isSelected = false});
}

class HistoryEntry {
  final DateTime date;
  final String type;
  final String description;

  HistoryEntry({required this.date, required this.type, required this.description});
}

class Settings {
  double fontSize;
  bool drugReminderEnabled;
  int drugReminderDays;
  bool appointmentDayReminderEnabled;
  bool appointmentTimeReminderEnabled;
  int appointmentReminderMinutes;
  String theme; 

  Settings({
    this.fontSize = 100.0,
    this.drugReminderEnabled = true,
    this.drugReminderDays = 30,
    this.appointmentDayReminderEnabled = true,
    this.appointmentTimeReminderEnabled = true,
    this.appointmentReminderMinutes = 60,
    this.theme = 'system',
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      fontSize: (json['fontSize'] ?? 100.0).toDouble(),
      drugReminderEnabled: json['drugReminderEnabled'] ?? true,
      drugReminderDays: json['drugReminderDays'] ?? 30,
      appointmentDayReminderEnabled: json['appointmentDayReminderEnabled'] ?? true,
      appointmentTimeReminderEnabled: json['appointmentTimeReminderEnabled'] ?? true,
      appointmentReminderMinutes: json['appointmentReminderMinutes'] ?? 60,
      theme: json['theme'] ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'drugReminderEnabled': drugReminderEnabled,
      'drugReminderDays': drugReminderDays,
      'appointmentDayReminderEnabled': appointmentDayReminderEnabled,
      'appointmentTimeReminderEnabled': appointmentTimeReminderEnabled,
      'appointmentReminderMinutes': appointmentReminderMinutes,
      'theme': theme,
    };
  }
}
