import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Importa il pacchetto Provider

// Importa le nostre schermate e i servizi API
import 'screens/home_page.dart';
import 'api/api_client.dart';
import 'api/auth_repository.dart';
import 'api/paziente_repository.dart';
import 'models/paziente.dart'; // Importa il modello Paziente
import 'providers/settings_provider.dart'; // Importa il SettingsProvider
import 'providers/profile_provider.dart'; // Importa il ProfileProvider

// Dichiarazione globale dei repository e di SharedPreferences.
late ApiClient apiClient;
late AuthRepository authRepository;
late PazienteRepository pazienteRepository;
late SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();

  apiClient = ApiClient();
  authRepository = AuthRepository(apiClient, prefs);
  pazienteRepository = PazienteRepository(apiClient);

  // Inizializza un profilo di default se non ne esiste nessuno
  // Questa logica è stata spostata in ProfileProvider per essere più robusta
  // ma ci assicuriamo che SharedPreferences abbia un valore iniziale per il primo avvio.
  final String? defaultCf = prefs.getString('active_paziente_cf');
  if (defaultCf == null || defaultCf.isEmpty) {
    await prefs.setString('active_paziente_name', 'Mario Rossi');
    await prefs.setString('active_paziente_cf', 'RSSMRA85M01H501X');
    await prefs.setString('active_paziente_phone', '+393331234567');
    // Aggiungi anche alla lista dei profili salvati se non c'è ancora
    final List<String> savedProfiliJson = prefs.getStringList('lista_profili_paziente') ?? [];
    if (savedProfiliJson.isEmpty) {
      final Paziente defaultPaziente = Paziente(
        nome: 'Mario Rossi',
        codiceFiscale: 'RSSMRA85M01H501X',
        numeroTelefono: '+393331234567',
        isDefault: true,
      );
      await prefs.setStringList('lista_profili_paziente', ['${defaultPaziente.nome}|${defaultPaziente.codiceFiscale}|${defaultPaziente.numeroTelefono}|${defaultPaziente.isDefault}']);
    }
    print('Profilo di default Mario Rossi inizializzato in SharedPreferences.');
  }


  runApp(
    // MultiProvider per fornire più istanze di ChangeNotifierProvider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const SegreteriaMedicoApp(),
    ),
  );
}

class SegreteriaMedicoApp extends StatelessWidget {
  const SegreteriaMedicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ottiene la scala dei caratteri dal SettingsProvider
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final double fontSizeScale = settingsProvider.fontSizeScale;

    return MaterialApp(
      title: 'Segreteria Medico',
      // Applica la scala dei caratteri a tutto il tema
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontSizeScale)),
          child: child!,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          primary: const Color(0xFF3B82F6), // Blu
          secondary: const Color(0xFF8B5CF6), // Viola
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          error: Colors.red.shade700,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 96, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 14),
          labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          labelMedium: TextStyle(fontSize: 16),
          labelSmall: TextStyle(fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 55),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3B82F6),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.red.shade700, width: 2.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.red.shade700, width: 2.5),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 18),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
        ),
        checkboxTheme: CheckboxThemeData( // Stile per i checkbox
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF3B82F6); // Colore primario quando selezionato
            }
            return Colors.grey.shade400; // Colore quando non selezionato
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: Colors.grey.shade500, width: 2),
        ),
        radioTheme: RadioThemeData( // Stile per i radio button
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF3B82F6);
            }
            return Colors.grey.shade400;
          }),
        ),
        switchTheme: SwitchThemeData( // Stile per gli switch
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF3B82F6);
            }
            return Colors.grey.shade400;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF3B82F6).withOpacity(0.5);
            }
            return Colors.grey.shade300;
          }),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}