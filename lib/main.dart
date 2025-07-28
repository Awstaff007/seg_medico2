import 'package:flutter/material.dart';
import 'package:seg_medico2/home_page.dart';
import 'package:seg_medico2/settings_page.dart';
import 'package:seg_medico2/medications_page.dart';
import 'package:seg_medico2/appointments_page.dart';
import 'package:seg_medico2/history_page.dart';
import 'package:seg_medico2/data/database.dart'; // Import your database
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/drift.dart' hide Column; // Import Value from drift, hide Column to avoid conflict

// Initialize Flutter Secure Storage
const _storage = FlutterSecureStorage();
late AppDatabase db; // Declare db globally

// Global function to get or create a user ID
Future<String> getCurrentUserId(AppDatabase database) async {
  String? userId = await _storage.read(key: 'user_id');
  if (userId == null) {
    userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.write(key: 'user_id', value: userId);
    // Insert new user and a default profile into the database
    await database.into(database.users).insert(UsersCompanion(id: Value(userId)));
    await database.into(database.profiles).insert(ProfilesCompanion(userId: Value(userId)));
  }
  return userId;
}

// Extension to easily access the database from anywhere
extension AppDatabaseExtension on BuildContext {
  AppDatabase get db => AppDatabase();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  db = AppDatabase(); // Initialize the database globally
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  String? _currentUserId; // Store the current user ID

  @override
  void initState() {
    super.initState();
    _initializeUserAndProfile();
  }

  Future<void> _initializeUserAndProfile() async {
    _currentUserId = await getCurrentUserId(db); // Use the global db instance
    // You can also ensure a profile exists here if not already created by getCurrentUserId
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if _currentUserId is null. If so, show a loading indicator.
    if (_currentUserId == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Define the list of pages using the global db and _currentUserId
    final List<Widget> pages = [
      HomePage(db: db, userId: _currentUserId!),
      MedicationsPage(db: db, userId: _currentUserId!),
      AppointmentsPage(db: db, userId: _currentUserId!),
      HistoryPage(db: db, userId: _currentUserId!),
      SettingsPage(db: db, userId: _currentUserId!),
    ];

    return MaterialApp(
      title: 'Segretario Medico',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system, // Or ThemeMode.light/dark based on user settings
      home: Scaffold(
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.healing),
              label: 'Farmaci',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Appuntamenti',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Storico',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Impostazioni',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Ensures all labels are shown
        ),
      ),
    );
  }
}
