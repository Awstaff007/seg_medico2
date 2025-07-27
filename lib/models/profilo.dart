// lib/models/profilo.dart
import 'dart:convert';

class Profilo {
  final String id;
  final String nome;
  final String cognome;
  final String cellulare;
  final String codiceFiscale; // Aggiunto codiceFiscale

  Profilo({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.cellulare,
    required this.codiceFiscale, // Aggiunto al costruttore
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'cellulare': cellulare,
      'codiceFiscale': codiceFiscale, // Aggiunto a toMap
    };
  }

  factory Profilo.fromMap(Map<String, dynamic> map) {
    return Profilo(
      id: map['id']?.toString() ?? '',
      nome: map['nome'] as String,
      cognome: map['cognome'] as String,
      cellulare: map['cellulare'] as String,
      codiceFiscale: map['codiceFiscale'] as String, // Aggiunto a fromMap
    );
  }

  String toJson() => json.encode(toMap());

  factory Profilo.fromJson(String source) => Profilo.fromMap(json.decode(source) as Map<String, dynamic>);

  Profilo copyWith({
    String? id,
    String? nome,
    String? cognome,
    String? cellulare,
    String? codiceFiscale, // Aggiunto a copyWith
  }) {
    return Profilo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      cellulare: cellulare ?? this.cellulare,
      codiceFiscale: codiceFiscale ?? this.codiceFiscale, // Aggiunto qui
    );
  }
}
