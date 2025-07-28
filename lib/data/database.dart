// lib/data/database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Questa direttiva è FONDAMENTALE. Indica a Dart che parte della classe AppDatabase
// è generata automaticamente nel file database.g.dart.
part 'database.g.dart';

// Definisci le tabelle del database

@DataClassName('User') // Aggiungi la classe per gli utenti
class Users extends Table {
  // Correzione: Rimuovi .notNull() e customConstraint('UNIQUE')
  // La proprietà PRIMARY KEY (definita sotto in primaryKey) implica già NOT NULL e UNIQUE.
  TextColumn get id => text().withLength(min: 1)(); // ID utente, es. email o UUID
  TextColumn get username => text().withLength(min: 1).unique()(); // Username deve essere unico
  TextColumn get passwordHash => text().withLength(min: 1)(); // Hash della password, non la password in chiaro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id}; // Imposta l'ID come chiave primaria
}


@DataClassName('Appointment')
class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().withLength(min: 1).references(Users, #id)(); // Riferimento all'utente
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get appointmentDate => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('Medication')
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().withLength(min: 1).references(Users, #id)(); // Riferimento all'utente
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get dosage => text().nullable()();
  TextColumn get frequency => text().nullable()();
  DateTimeColumn get nextDose => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DataClassName('HistoryEntry')
class HistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().withLength(min: 1).references(Users, #id)(); // Riferimento all'utente
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get type => text().withLength(min: 1)(); // es. 'appointment_completed', 'medication_taken'
  TextColumn get description => text().withLength(min: 1)();
}

@DriftDatabase(tables: [Users, Appointments, Medications, HistoryEntries])
class AppDatabase extends _$AppDatabase {
  // Il costruttore di AppDatabase deve accettare un QueryExecutor opzionale
  // Questo è importante per i test e per come Drift inizializza il database.
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // --- Operazioni per Utenti ---

  // Trova un utente per username
  Future<User?> getUser(String username) {
    return (select(users)..where((tbl) => tbl.username.equals(username))).getSingleOrNull();
  }

  // Crea un nuovo utente
  Future<int> createUser(UsersCompanion entry) {
    return into(users).insert(entry);
  }

  // --- Operazioni per Appuntamenti ---

  // Ottieni tutti gli appuntamenti per un utente specifico
  Future<List<Appointment>> getAllAppointmentsForUser(String userId) {
    return (select(appointments)..where((tbl) => tbl.userId.equals(userId))).get();
  }

  // Osserva tutti gli appuntamenti per un utente specifico (Stream)
  Stream<List<Appointment>> watchAllAppointmentsForUser(String userId) {
    // Correzione: Utilizza la sintassi più concisa per OrderingTerm
    return select(appointments)
        .where((tbl) => tbl.userId.equals(userId))
        .orderBy([OrderingTerm.asc(appointments.appointmentDate)]) // Sintassi concisa
        .watch();
  }

  // Aggiungi un nuovo appuntamento
  Future<int> addAppointment(AppointmentsCompanion entry) {
    return into(appointments).insert(entry);
  }

  // Aggiorna un appuntamento esistente
  Future<bool> updateAppointment(AppointmentsCompanion entry) {
    return update(appointments).replace(entry);
  }

  // Elimina un appuntamento
  Future<int> deleteAppointment(int id) {
    return (delete(appointments)..where((tbl) => tbl.id.equals(id))).go();
  }

  // --- Operazioni per Farmaci ---

  // Ottieni tutti i farmaci per un utente specifico
  Future<List<Medication>> getAllMedicationsForUser(String userId) {
    return (select(medications)..where((tbl) => tbl.userId.equals(userId))).get();
  }

  // Osserva tutti i farmaci per un utente specifico (Stream)
  Stream<List<Medication>> watchAllMedicationsForUser(String userId) {
    // Correzione: Utilizza la sintassi più concisa per OrderingTerm
    return select(medications)
        .where((tbl) => tbl.userId.equals(userId))
        .orderBy([OrderingTerm.asc(medications.name)]) // Sintassi concisa
        .watch();
  }

  // Aggiungi un nuovo farmaco
  Future<int> addMedication(MedicationsCompanion entry) {
    return into(medications).insert(entry);
  }

  // Aggiorna un farmaco esistente
  Future<bool> updateMedication(MedicationsCompanion entry) {
    return update(medications).replace(entry);
  }

  // Elimina un farmaco
  Future<int> deleteMedication(int id) {
    return (delete(medications)..where((tbl) => tbl.id.equals(id))).go();
  }

  // --- Operazioni per Cronologia ---

  // Aggiungi una nuova voce di cronologia
  Future<int> addHistoryEntry(HistoryEntriesCompanion history) => into(historyEntries).insert(history);

  // Ottieni la cronologia per un utente specifico
  Future<List<HistoryEntry>> getHistoryForUser(String userId) {
    // Correzione: Utilizza la sintassi più concisa per OrderingTerm
    return select(historyEntries)
        .where((tbl) => tbl.userId.equals(userId))
        .orderBy([OrderingTerm.desc(historyEntries.timestamp)]) // Sintassi concisa
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
