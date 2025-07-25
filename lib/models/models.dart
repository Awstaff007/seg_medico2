// lib/models/models.dart

class PazienteInfo {
  final String nome;
  final String cognome;
  final String cellulare;

  PazienteInfo({required this.nome, required this.cognome, required this.cellulare});

  factory PazienteInfo.fromJson(Map<String, dynamic> json) {
    return PazienteInfo(
      nome: json['nome'] ?? '',
      cognome: json['cognome'] ?? '',
      cellulare: json['cellulare'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cognome': cognome,
      'cellulare': cellulare,
    };
  }
}

class MedicoInfo {
  final String nome;
  final bool servizio;
  final bool appuntamenti;
  final bool appuntamenti2;
  final bool consigli;
  final bool disdette;
  final bool farmaci;
  final int orario;

  MedicoInfo({
    required this.nome,
    required this.servizio,
    required this.appuntamenti,
    required this.appuntamenti2,
    required this.consigli,
    required this.disdette,
    required this.farmaci,
    required this.orario,
  });

  factory MedicoInfo.fromJson(Map<String, dynamic> json) {
    return MedicoInfo(
      nome: json['nome'] ?? '',
      servizio: json['servizio'] ?? false,
      appuntamenti: json['appuntamenti'] ?? false,
      appuntamenti2: json['appuntamenti2'] ?? false,
      consigli: json['consigli'] ?? false,
      disdette: json['disdette'] ?? false,
      farmaci: json['farmaci'] ?? false,
      orario: json['orario'] ?? 0,
    );
  }
}

class Ambulatorio {
  final int id;
  final String nome;

  Ambulatorio({required this.id, required this.nome});

  factory Ambulatorio.fromJson(Map<String, dynamic> json) {
    return Ambulatorio(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? '',
    );
  }
}

class UserInfo {
  final List<dynamic> note;
  final PazienteInfo paziente;
  final MedicoInfo medico;
  final List<Ambulatorio> ambulatori;
  final bool app15gg;
  final String giorni;

  UserInfo({
    required this.note,
    required this.paziente,
    required this.medico,
    required this.ambulatori,
    required this.app15gg,
    required this.giorni,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      note: json['note'] ?? [],
      paziente: PazienteInfo.fromJson(json['paziente'] ?? {}),
      medico: MedicoInfo.fromJson(json['medico'] ?? {}),
      ambulatori: (json['ambulatori'] as List<dynamic>?)
          ?.map((e) => Ambulatorio.fromJson(e))
          .toList() ??
          [],
      app15gg: json['app15gg'] ?? false,
      giorni: json['giorni'] ?? '',
    );
  }
}

class AppointmentSlot {
  final String data;
  final String inizio;
  final String fine;

  AppointmentSlot({required this.data, required this.inizio, required this.fine});

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      data: json['data'] ?? '',
      inizio: json['inizio'] ?? '',
      fine: json['fine'] ?? '',
    );
  }
}

class Appointment {
  final int id;
  final String data;
  final String inizio;
  final String fine;
  final String ambulatorio;

  Appointment({
    required this.id,
    required this.data,
    required this.inizio,
    required this.fine,
    required this.ambulatorio,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? 0,
      data: json['data'] ?? '',
      inizio: json['inizio'] ?? '',
      fine: json['fine'] ?? '',
      ambulatorio: json['ambulatorio'] ?? '',
    );
  }
}

class Profile {
  final String name;
  final String codFis;
  final String phoneNumber;
  bool isDefault;

  Profile({required this.name, required this.codFis, required this.phoneNumber, this.isDefault = false});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'],
      codFis: json['codFis'],
      phoneNumber: json['phoneNumber'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'codFis': codFis,
      'phoneNumber': phoneNumber,
      'isDefault': isDefault,
    };
  }
}