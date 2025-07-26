// lib/models/profile.dart
import 'package:uuid/uuid.dart';

class Profile {
  String id; // Aggiunto per identificare univocamente i profili
  String name;
  String codiceFiscale;
  String phoneNumber;
  String email;
  String address;
  String city;
  String province;
  String cap;
  DateTime? birthDate;
  String? notes;

  Profile({
    String? id, // Reso opzionale per la creazione di nuovi profili
    required this.name,
    required this.codiceFiscale,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.city,
    required this.province,
    required this.cap,
    this.birthDate,
    this.notes,
  }) : id = id ?? const Uuid().v4(); // Genera un ID se non fornito

  // Converte l'oggetto Profile in una mappa JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'codiceFiscale': codiceFiscale,
        'phoneNumber': phoneNumber,
        'email': email,
        'address': address,
        'city': city,
        'province': province,
        'cap': cap,
        'birthDate': birthDate?.toIso8601String(), // Converte DateTime in stringa ISO 8601
        'notes': notes,
      };

  // Crea un oggetto Profile da una mappa JSON
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'],
        name: json['name'],
        codiceFiscale: json['codiceFiscale'],
        phoneNumber: json['phoneNumber'],
        email: json['email'],
        address: json['address'],
        city: json['city'],
        province: json['province'],
        cap: json['cap'],
        birthDate: json['birthDate'] != null
            ? DateTime.tryParse(json['birthDate']) // Parsa la stringa ISO 8601 in DateTime
            : null,
        notes: json['notes'],
      );
}
