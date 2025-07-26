// lib/models/models.dart

import 'package:intl/intl.dart';

class Profile {
  final String name;
  final String codFis; // Used instead of fiscalCode
  final String phoneNumber;
  final String? email; // Added for compatibility
  final bool isDefault;

  Profile({
    required this.name,
    required this.codFis,
    required this.phoneNumber,
    this.email, // Include in constructor
    this.isDefault = false,
  });

  // Factory constructor for creating a new Profile instance from a map (JSON)
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String,
      codFis: json['codFis'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      isDefault: json['isDefault'] as bool? ?? false, // Handle optional and default
    );
  }

  // Method for converting a Profile instance to a map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'codFis': codFis,
      'phoneNumber': phoneNumber,
      'email': email,
      'isDefault': isDefault,
    };
  }

  // Added copyWith method for immutability and easy updates
  Profile copyWith({
    String? name,
    String? codFis,
    String? phoneNumber,
    String? email,
    bool? isDefault,
  }) {
    return Profile(
      name: name ?? this.name,
      codFis: codFis ?? this.codFis,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class Ambulatorio {
  final int id;
  final String name;

  Ambulatorio({required this.id, required this.name});

  factory Ambulatorio.fromJson(Map<String, dynamic> json) {
    return Ambulatorio(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class UserInfo {
  final String name;
  final String? email;
  final String? phone;
  final List<Ambulatorio> ambulatori; // Added as per errors

  UserInfo({
    required this.name,
    this.email,
    this.phone,
    this.ambulatori = const [], // Initialize with an empty list
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      ambulatori: (json['ambulatori'] as List<dynamic>?)
              ?.map((e) => Ambulatorio.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'ambulatori': ambulatori.map((e) => e.toJson()).toList(),
    };
  }

  UserInfo copyWith({
    String? name,
    String? email,
    String? phone,
    List<Ambulatorio>? ambulatori,
  }) {
    return UserInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      ambulatori: ambulatori ?? this.ambulatori,
    );
  }
}

class Appointment {
  final int id;
  final String data;
  final String inizio;
  final String fine;
  final int ambulatorioId; // Changed to int, assuming API returns int
  final int numero; // Changed to int, assuming API returns int
  final String? ambulatorioName; // Added for display in CronologiaScreen

  Appointment({
    required this.id,
    required this.data,
    required this.inizio,
    required this.fine,
    required this.ambulatorioId,
    required this.numero,
    this.ambulatorioName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      data: json['data'] as String,
      inizio: json['inizio'] as String,
      fine: json['fine'] as String,
      ambulatorioId: json['ambulatorioId'] as int,
      numero: json['numero'] as int,
      ambulatorioName: json['ambulatorioName'] as String?, // Assuming API provides this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'inizio': inizio,
      'fine': fine,
      'ambulatorioId': ambulatorioId,
      'numero': numero,
      'ambulatorioName': ambulatorioName,
    };
  }

  Appointment copyWith({
    int? id,
    String? data,
    String? inizio,
    String? fine,
    int? ambulatorioId,
    int? numero,
    String? ambulatorioName,
  }) {
    return Appointment(
      id: id ?? this.id,
      data: data ?? this.data,
      inizio: inizio ?? this.inizio,
      fine: fine ?? this.fine,
      ambulatorioId: ambulatorioId ?? this.ambulatorioId,
      numero: numero ?? this.numero,
      ambulatorioName: ambulatorioName ?? this.ambulatorioName,
    );
  }
}

// Assumed structure for AppointmentSlot based on its usage
// This model will likely be used internally and converted to a Map for the UI
class AppointmentSlot {
  final DateTime date; // Changed to DateTime for easier manipulation
  final String time; // e.g., "10:00"
  final int ambulatorioId;
  final int numero;

  AppointmentSlot({
    required this.date,
    required this.time,
    required this.ambulatorioId,
    required this.numero,
  });

  // Example factory constructor for parsing from API response (adjust as needed)
  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      date: DateFormat('yyyy-MM-dd').parse(json['data']), // Assuming 'data' is yyyy-MM-dd
      time: json['inizio'], // Assuming 'inizio' is the time string
      ambulatorioId: json['ambulatorioId'] as int,
      numero: json['numero'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': DateFormat('yyyy-MM-dd').format(date),
      'inizio': time,
      'ambulatorioId': ambulatorioId,
      'numero': numero,
    };
  }
}