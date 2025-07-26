import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/screens/home_screen.dart';
import 'package:seg_medico/services/api_service.dart';
import 'package:seg_medico/utils/profile_manager.dart';
import 'package:seg_medico/themes/app_theme.dart';
import 'package:seg_medico/screens/appuntamenti_screen.dart';
import 'package:seg_medico/screens/farmaci_screen.dart';
import 'package:seg_medico/screens/cronologia_screen.dart';
import 'package:seg_medico/screens/settings_screen.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);

  // Inizializza i servizi che verranno iniettati nel provider
  final profileManager = ProfileManager();
  await profileManager.init();

  final apiService = ApiService();

  runApp(MyApp(
    profileManager: profileManager,
    apiService: apiService,
  ));
}

class MyApp extends StatelessWidget {
  final ProfileManager profileManager;
  final ApiService apiService;

  const MyApp({
    Key? key,
    required this.profileManager,
    required this.apiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(apiService, profileManager),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Segretario Medico',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/farmaci': (context) => const FarmaciScreen(),
              '/appuntamenti': (context) => const AppuntamentiScreen(),
              '/cronologia': (context) => const CronologiaScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
