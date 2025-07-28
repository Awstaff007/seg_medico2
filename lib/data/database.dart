// lib/data/database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

@DataClassName('User')
class Users extends Table {
  TextColumn get id => text().customConstraint('UNIQUE NOT NULL')();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()(); // Store hashed passwords
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Profile')
class Profiles extends Table {
  TextColumn get userId => text().references(Users, #id)();
  RealColumn get granularFontSizeScale => real().withDefault(const Constant(1.0))();
  BoolColumn get receiveReminders => boolean().withDefault(const Constant(true))();
  IntColumn get reminderTimeMinutesBefore => integer().withDefault(const Constant(30))();
  IntColumn get recipeAlertDays => integer().withDefault(const Constant(7))();
  IntColumn get appointmentReminderDaysBefore => integer().withDefault(const Constant(1))();
  TextColumn get selectedTheme => text().withDefault(const Constant('system'))();
  RealColumn get homepageFontSizeScale => real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {userId};
}

@DataClassName('Medication')
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get dosage => text().withLength(min: 0, max: 50).nullable()();
  TextColumn get frequency => text().withLength(min: 1, max: 50)(); // Aggiunto
  TextColumn get notes => text().withLength(min: 0, max: 500)(); // Aggiunto
  DateTimeColumn get startDate => dateTime()(); // Aggiunto
  DateTimeColumn get endDate => dateTime()(); // Aggiunto
  DateTimeColumn get nextDose => dateTime().nullable()(); // Mantenuto, se necessario per la prossima dose specifica
}

@DataClassName('Appointment')
class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get location => text().withLength(min: 0, max: 200).nullable()();
  DateTimeColumn get appointmentDateTime => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('History')
class Histories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get type => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().withLength(min: 1, max: 500)();
  IntColumn get medicationId => integer().nullable().references(Medications, #id)();
  IntColumn get appointmentId => integer().nullable().references(Appointments, #id)();
}

@DriftDatabase(tables: [Users, Profiles, Medications, Appointments, Histories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- User Queries ---
  Future<void> createUser(UsersCompanion user) async {
    await into(users).insert(user);
    // Create a default profile for the new user
    await into(profiles).insert(
      ProfilesCompanion(
        userId: Value(user.id.value), // Usa .value per estrarre la stringa dall'Expression
        homepageFontSizeScale: const Value(1.0),
      ),
    );
  }

  Future<User?> getUser(String username) =>
      (select(users)..where((u) => u.username.equals(username))).getSingleOrNull();

  Future<User?> getUserById(String id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<bool> updateUser(UsersCompanion user) => update(users).replace(user);

  Future<int> deleteUser(String userId) async {
    await (delete(profiles)..where((p) => p.userId.equals(userId))).go();
    await (delete(medications)..where((m) => m.userId.equals(userId))).go();
    await (delete(appointments)..where((a) => a.userId.equals(userId))).go();
    await (delete(histories)..where((h) => h.userId.equals(userId))).go();
    return (delete(users)..where((u) => u.id.equals(userId))).go();
  }

  // --- Profile Queries ---
  Future<Profile?> getProfileForUser(String userId) =>
      (select(profiles)..where((p) => p.userId.equals(userId))).getSingleOrNull();

  Stream<Profile?> watchProfileForUser(String userId) =>
      (select(profiles)..where((p) => p.userId.equals(userId))).watchSingleOrNull();

  Future<void> updateProfile(ProfilesCompanion profile) => update(profiles).replace(profile);

  // --- Medication Queries ---
  Stream<List<Medication>> watchMedicationsForUser(String userId) {
    return (select(medications)..where((m) => m.userId.equals(userId))).watch();
  }

  // Metodo rinominato da insertMedication a addMedication
  Future<int> addMedication(MedicationsCompanion medication) =>
      into(medications).insert(medication);

  // Modificato per accettare MedicationsCompanion
  Future<bool> updateMedication(MedicationsCompanion medication) => update(medications).replace(medication);

  // Modificato per accettare l'ID
  Future<int> deleteMedication(int medicationId) =>
      (delete(medications)..where((t) => t.id.equals(medicationId))).go();

  // --- Appointment Queries ---
  Stream<List<Appointment>> watchAppointmentsForUser(String userId) {
    return (select(appointments)..where((a) => a.userId.equals(userId))).watch();
  }

  // Metodo rinominato da insertAppointment a addAppointment
  Future<int> addAppointment(AppointmentsCompanion appointment) =>
      into(appointments).insert(appointment);

  // Modificato per accettare AppointmentsCompanion
  Future<bool> updateAppointment(AppointmentsCompanion appointment) =>
      update(appointments).replace(appointment);

  // Modificato per accettare l'ID
  Future<int> deleteAppointment(int appointmentId) =>
      (delete(appointments)..where((a) => a.id.equals(appointmentId))).go();

  // --- History Queries ---
  Stream<List<History>> watchHistoryForUser(String userId) {
    return (select(histories)..where((h) => h.userId.equals(userId))).watch();
  }

  // Metodo rinominato da insertHistory a addHistoryEntry
  Future<int> addHistoryEntry(HistoryEntriesCompanion history) => into(histories).insert(history);

  Future<void> deleteAppointmentHistory(int appointmentId) async {
    await (delete(histories)..where((h) => h.appointmentId.equals(appointmentId))).go();
  }

  Future<void> deleteMedicationHistory(int medicationId) async {
    await (delete(histories)..where((h) => h.medicationId.equals(medicationId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
