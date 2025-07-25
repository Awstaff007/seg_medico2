class Farmaco {
  final String id; // L'ID del farmaco, se fornito da un'API
  final String nome;
  bool selezionato;

  Farmaco({
    this.id = '', // ID vuoto per farmaci locali
    required this.nome,
    this.selezionato = false,
  });

  // Se in futuro avrai un'API che restituisce farmaci, puoi usare un fromJson
  factory Farmaco.fromJson(Map<String, dynamic> json) {
    return Farmaco(
      id: json['id'] ?? '',
      nome: json['nome'] ?? 'Farmaco Sconosciuto',
      selezionato: json['selezionato'] ?? false, // Se l'API restituisce anche lo stato di selezione
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'selezionato': selezionato,
    };
  }
}