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
  // CORREZIONE: Aggiunto NOT NULL e ON DELETE CASCADE per robustezza
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get doctorName => text()();
  TextColumn get location => text()();
  DateTimeColumn get appointmentDate => dateTime()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  // CORREZIONE: Aggiunto NOT NULL e ON DELETE CASCADE
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get name => text()();
  TextColumn get dosage => text()();
  TextColumn get frequency => text()();
  DateTimeColumn get nextDose => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class MedicalHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  // CORREZIONE: Aggiunto NOT NULL e ON DELETE CASCADE
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get eventType => text()();
  TextColumn get details => text()();
  DateTimeColumn get timestamp => dateTime()();
}

@DriftDatabase(tables: [Users, Appointments, Medications, MedicalHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(appointments, appointments.isCompleted);
          await m.addColumn(medications, medications.nextDose);
          await m.addColumn(medications, medications.isActive);
        }
      },
    );
  }

  // --- Metodi Utenti ---
  Future<int> createUser(UsersCompanion entry) {
    return into(users).insert(entry);
  }

  Future<User?> getUserById(int id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }
  
  Future<User?> getUser(String name) {
    return (select(users)..where((tbl) => tbl.name.equals(name))).getSingleOrNull();
  }


  // --- Metodi Appuntamenti ---
  Stream<List<Appointment>> watchAllAppointmentsForUser(int userId) {
    return (select(appointments)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.appointmentDate)]))
        .watch();
  }
  
  Future<List<Appointment>> getAllAppointmentsForUser(int userId) {
      return (select(appointments)..where((tbl) => tbl.userId.equals(userId))).get();
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

  // --- Metodi Farmaci ---
  Stream<List<Medication>> watchAllMedicationsForUser(int userId) {
    return (select(medications)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }
  
  Future<List<Medication>> getAllMedicationsForUser(int userId) {
      return (select(medications)..where((tbl) => tbl.userId.equals(userId))).get();
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

  // --- Metodi Cronologia ---
  Stream<List<MedicalHistoryData>> watchMedicalHistory(int userId) {
    return (select(medicalHistory)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }
  
  Future<List<MedicalHistoryData>> getHistoryForUser(int userId) {
      return (select(medicalHistory)..where((tbl) => tbl.userId.equals(userId))).get();
  }

  Future<int> addHistoryEntry(MedicalHistoryCompanion entry) {
    return into(medicalHistory).insert(entry);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file, logStatements: true);
  });
}
