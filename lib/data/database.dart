import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Definizione delle tabelle
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get email => text().nullable()();
}

class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  TextColumn get doctorName => text()();
  TextColumn get location => text()();
  DateTimeColumn get appointmentDate => dateTime()();
  TextColumn get notes => text().nullable()();
}

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  TextColumn get name => text()();
  TextColumn get dosage => text()();
  TextColumn get frequency => text()();
}

class MedicalHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  TextColumn get eventType => text()();
  TextColumn get details => text()();
  DateTimeColumn get timestamp => dateTime()();
}

@DriftDatabase(tables: [Users, Appointments, Medications, MedicalHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Metodi per le query sugli utenti
  Future<int> addUser(UsersCompanion entry) {
    return into(users).insert(entry);
  }

  Future<User?> getUserById(int id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // Metodi per le query sugli appuntamenti
  /// CORREZIONE: La query è stata riscritta per usare correttamente
  /// gli operatori a cascata (..) per where e orderBy.
  /// L'errato '.get()' è stato rimosso dalla costruzione dello stream.
  Stream<List<Appointment>> watchAppointments(int userId) {
    return (select(appointments)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.appointmentDate)]))
        .watch();
  }

  Future<int> addAppointment(AppointmentsCompanion entry) {
    return into(appointments).insert(entry);
  }

  Future<bool> updateAppointment(AppointmentsCompanion entry) {
    return update(appointments).replace(entry);
  }

  Future<int> deleteAppointment(int id) {
    return (delete(appointments)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Metodi per le query sui farmaci
  /// CORREZIONE: La query è stata riscritta con la sintassi corretta
  /// per il chaining dei metodi in drift.
  Stream<List<Medication>> watchMedications(int userId) {
    return (select(medications)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  Future<int> addMedication(MedicationsCompanion entry) {
    return into(medications).insert(entry);
  }

  Future<bool> updateMedication(MedicationsCompanion entry) {
    return update(medications).replace(entry);
  }

  Future<int> deleteMedication(int id) {
    return (delete(medications)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Metodi per le query sulla cronologia medica
  /// CORREZIONE: La query è stata riscritta con la sintassi corretta.
  /// È stato anche corretto il riferimento alla tabella da 'historyEntries'
  /// a 'medicalHistory', che è il nome corretto generato da drift.
  Stream<List<MedicalHistoryData>> watchMedicalHistory(int userId) {
    return (select(medicalHistory)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  Future<int> addMedicalHistory(MedicalHistoryCompanion entry) {
    return into(medicalHistory).insert(entry);
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
