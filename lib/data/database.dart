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
  // Renamed for clarity and consistency with camelCase
  BoolColumn get receiveReminders => boolean().withDefault(const Constant(true))();
  IntColumn get reminderTimeMinutesBefore => integer().withDefault(const Constant(30))(); // Renamed
  IntColumn get recipeAlertDays => integer().withDefault(const Constant(7))(); // Renamed
  IntColumn get appointmentReminderDaysBefore => integer().withDefault(const Constant(1))(); // Renamed
  TextColumn get selectedTheme => text().withDefault(const Constant('system'))(); // Renamed
  
  @override
  Set<Column> get primaryKey => {userId};
}

@DataClassName('Medication')
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get dosage => text().withLength(min: 0, max: 50).nullable()();
  DateTimeColumn get nextDose => dateTime().nullable()();
  // Removed explicit primaryKey as autoIncrement() handles it
}

@DataClassName('Appointment')
class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get location => text().withLength(min: 0, max: 200).nullable()();
  DateTimeColumn get appointmentDateTime => dateTime()(); // Renamed from 'dateTime'
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  // Removed explicit primaryKey as autoIncrement() handles it
}

@DataClassName('History')
class Histories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get timestamp => dateTime()(); // Changed to DateTimeColumn for correct comparison
  TextColumn get type => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().withLength(min: 1, max: 500)();
  IntColumn get medicationId => integer().nullable().references(Medications, #id)();
  IntColumn get appointmentId => integer().nullable().references(Appointments, #id)();
  // Removed explicit primaryKey as autoIncrement() handles it
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
      ProfilesCompanion(userId: user.id.value),
    );
  }
  Future<User?> getUser(String username) =>
      (select(users)..where((u) => u.username.equals(username))).getSingleOrNull();

  Future<User?> getUserById(String id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<bool> updateUser(UsersCompanion user) => update(users).replace(user); // Returns bool for replace

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

  // Use replace for updates, ensuring existing row is updated or inserted if not exists
  Future<void> updateProfile(ProfilesCompanion profile) => update(profiles).replace(profile);

  // --- Medication Queries ---
  Stream<List<Medication>> watchMedicationsForUser(String userId) {
    return (select(medications)..where((m) => m.userId.equals(userId))).watch();
  }

  Future<int> insertMedication(MedicationsCompanion medication) =>
      into(medications).insert(medication);

  Future<bool> updateMedication(Medication medication) => update(medications).replace(medication);

  Future<int> deleteMedication(Medication medication) =>
      (delete(medications)..where((t) => t.id.equals(medication.id))).go();

  // --- Appointment Queries ---
  Stream<List<Appointment>> watchAppointmentsForUser(String userId) {
    return (select(appointments)..where((a) => a.userId.equals(userId))).watch();
  }

  Future<int> insertAppointment(AppointmentsCompanion appointment) =>
      into(appointments).insert(appointment);

  Future<bool> updateAppointment(Appointment appointment) =>
      update(appointments).replace(appointment);

  Future<int> deleteAppointment(Appointment appointment) =>
      (delete(appointments)..where((a) => a.id.equals(appointment.id))).go();

  // --- History Queries ---
  Stream<List<History>> watchHistoryForUser(String userId) {
    return (select(histories)..where((h) => h.userId.equals(userId))).watch();
  }

  Future<int> insertHistory(HistoriesCompanion history) => into(histories).insert(history);

  // Method to delete history entries associated with a deleted appointment
  Future<void> deleteAppointmentHistory(int appointmentId) async {
    await (delete(histories)..where((h) => h.appointmentId.equals(appointmentId))).go();
  }

  // Method to delete history entries associated with a deleted medication
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