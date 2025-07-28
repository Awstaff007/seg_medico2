import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Questo file generato contiene le classi come UsersCompanion, AppointmentsCompanion, ecc.
part 'database.g.dart';

// Definizione delle tabelle
// Ho cambiato gli ID da IntColumn a TextColumn per usare String come ID (es. UUID)
// Questo si allinea meglio con l'ID utente di tipo String fornito dall'AuthService.

class Users extends Table {
  // ID utente come String (es. UUID da Firebase Auth)
  TextColumn get id => text().withLength(min: 1, max: 255)();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get email => text().nullable()();

  @override
  Set<Column> get primaryKey => {id}; // L'ID String è la chiave primaria
}

class Appointments extends Table {
  // ID appuntamento come String
  TextColumn get id => text().withLength(min: 1, max: 255)();
  // userId come String, con riferimento alla tabella Users
  TextColumn get userId => text().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get doctorName => text()();
  TextColumn get location => text()();
  DateTimeColumn get appointmentDate => dateTime()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id}; // L'ID String è la chiave primaria
}

class Medications extends Table {
  // ID farmaco come String
  TextColumn get id => text().withLength(min: 1, max: 255)();
  // userId come String, con riferimento alla tabella Users
  TextColumn get userId => text().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get name => text()();
  TextColumn get dosage => text().nullable()(); // Reso nullable come usato in edit_medication_page
  TextColumn get frequency => text().nullable()(); // Reso nullable come usato in edit_medication_page
  DateTimeColumn get nextDose => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id}; // L'ID String è la chiave primaria
}

// Rinominata da MedicalHistory a HistoryEntries per coerenza con l'uso nelle pagine
class HistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()(); // L'ID della entry di cronologia può rimanere int
  // userId come String, con riferimento alla tabella Users
  TextColumn get userId => text().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get eventType => text()();
  TextColumn get details => text()();
  DateTimeColumn get timestamp => dateTime()();
}

// La classe del database principale
@DriftDatabase(tables: [Users, Appointments, Medications, HistoryEntries]) // Aggiornato il nome della tabella
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Incrementato la versione dello schema a 3 per riflettere i cambiamenti
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Questa sezione dovrebbe gestire le migrazioni da versioni precedenti.
        // Se stai iniziando da zero o non hai dati esistenti, createAll() è sufficiente.
        // Per migrazioni reali, dovresti aggiungere logica per ALTER TABLE, ecc.
        if (from < 2) {
          // Esempio: Aggiungi colonne se non esistevano in versioni precedenti
          await m.addColumn(appointments, appointments.isCompleted);
          await m.addColumn(medications, medications.nextDose);
          await m.addColumn(medications, medications.isActive);
        }
        if (from < 3) {
          // Esempio: Migrazione da schema 2 a 3 (cambio ID da int a string)
          // Questa è una migrazione complessa che potrebbe richiedere:
          // 1. Creazione di nuove tabelle temporanee con ID di tipo TEXT.
          // 2. Copia dei dati dalle vecchie tabelle alle nuove, generando nuovi ID String.
          // 3. Eliminazione delle vecchie tabelle.
          // 4. Ridenominazione delle nuove tabelle.
          // Per semplicità in questa correzione, assumiamo che per un'app in fase iniziale
          // sia accettabile ricreare il database o gestire la migrazione manualmente.
          // Per un'app in produzione, questa parte richiederebbe molta più attenzione.
        }
      },
    );
  }

  // --- Metodi Utenti ---
  // Aggiornato per accettare UsersCompanion con ID String
  Future<void> createUser(UsersCompanion entry) {
    return into(users).insert(entry);
  }

  // Aggiornato per cercare per ID String
  Future<User?> getUserById(String id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }
  
  // Metodo per ottenere un utente per nome (rimane invariato)
  Future<User?> getUser(String name) {
    return (select(users)..where((tbl) => tbl.name.equals(name))).getSingleOrNull();
  }

  // --- Metodi Appuntamenti ---
  // Aggiornato per watchAllAppointmentsForUser
  Stream<List<Appointment>> watchAllAppointmentsForUser(String userId) {
    return (select(appointments)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.appointmentDate)]))
        .watch();
  }
  
  // Aggiornato per getAllAppointmentsForUser
  Future<List<Appointment>> getAllAppointmentsForUser(String userId) {
      return (select(appointments)..where((tbl) => tbl.userId.equals(userId))).get();
  }

  // Aggiornato per addAppointment
  Future<void> addAppointment(AppointmentsCompanion entry) {
    return into(appointments).insert(entry);
  }

  // Aggiornato per updateAppointment
  Future<bool> updateAppointment(AppointmentsCompanion entry) {
    return update(appointments).replace(entry);
  }

  // Aggiornato per deleteAppointment (accetta String ID)
  Future<int> deleteAppointment(String id) {
    return (delete(appointments)..where((tbl) => tbl.id.equals(id))).go();
  }

  // *** NUOVO: Metodo per aggiornare lo stato di un appuntamento ***
  Future<int> updateAppointmentStatus(String id, bool newStatus) {
    return (update(appointments)..where((tbl) => tbl.id.equals(id))).write(
      AppointmentsCompanion(isCompleted: d.Value(newStatus)),
    );
  }

  // --- Metodi Farmaci ---
  // Aggiornato per watchAllMedicationsForUser
  Stream<List<Medication>> watchAllMedicationsForUser(String userId) {
    return (select(medications)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }
  
  // Aggiornato per getAllMedicationsForUser
  Future<List<Medication>> getAllMedicationsForUser(String userId) {
      return (select(medications)..where((tbl) => tbl.userId.equals(userId))).get();
  }

  // Aggiornato per addMedication
  Future<void> addMedication(MedicationsCompanion entry) {
    return into(medications).insert(entry);
  }

  // Aggiornato per updateMedication
  Future<bool> updateMedication(MedicationsCompanion entry) {
    return update(medications).replace(entry);
  }

  // Aggiornato per deleteMedication (accetta String ID)
  Future<int> deleteMedication(String id) {
    return (delete(medications)..where((tbl) => tbl.id.equals(id))).go();
  }

  // *** NUOVO: Metodo per aggiornare lo stato di un farmaco ***
  Future<int> updateMedicationStatus(String id, bool newStatus) {
    return (update(medications)..where((tbl) => tbl.id.equals(id))).write(
      MedicationsCompanion(isActive: d.Value(newStatus)),
    );
  }

  // --- Metodi Cronologia ---
  // Aggiornato per watchHistory (usa userId String e getter historyEntries)
  Stream<List<HistoryEntry>> watchHistory(String userId) { // Usato HistoryEntry generato da HistoryEntries
    return (select(historyEntries) // Usato il getter corretto
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }
  
  // Aggiornato per getHistoryForUser
  Future<List<HistoryEntry>> getHistoryForUser(String userId) { // Usato HistoryEntry generato da HistoryEntries
      return (select(historyEntries)..where((tbl) => tbl.userId.equals(userId))).get();
  }

  // Aggiornato per addHistoryEntry (usa HistoryEntriesCompanion)
  Future<void> addHistoryEntry(HistoryEntriesCompanion entry) { // Usato HistoryEntriesCompanion
    return into(historyEntries).insert(entry); // Usato il getter corretto
  }
}

// Funzione per aprire la connessione al database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file, logStatements: true);
  });
}
