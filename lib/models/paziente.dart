class Paziente {
  final String nome;
  final String codiceFiscale;
  final String numeroTelefono;
  bool isDefault; // Ora non è più final, può essere modificato

  Paziente({
    required this.nome,
    required this.codiceFiscale,
    required this.numeroTelefono,
    this.isDefault = false,
  });

  // Metodo per creare un oggetto Paziente da un JSON (ad esempio, dalla risposta API)
  factory Paziente.fromJson(Map<String, dynamic> json) {
    return Paziente(
      nome: json['nome'] ?? 'Nome Sconosciuto',
      codiceFiscale: json['codice_fiscale'] ?? '',
      numeroTelefono: json['cellulare'] ?? '',
      isDefault: false, // Lo stato di default è gestito localmente
    );
  }

  // Metodo per convertire l'oggetto Paziente in un formato serializzabile (es. per SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'codice_fiscale': codiceFiscale,
      'numero_telefono': numeroTelefono,
      'is_default': isDefault,
    };
  }

  // Metodo copyWith per creare una nuova istanza di Paziente con proprietà modificate
  Paziente copyWith({
    String? nome,
    String? codiceFiscale,
    String? numeroTelefono,
    bool? isDefault,
  }) {
    return Paziente(
      nome: nome ?? this.nome,
      codiceFiscale: codiceFiscale ?? this.codiceFiscale,
      numeroTelefono: numeroTelefono ?? this.numeroTelefono,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}