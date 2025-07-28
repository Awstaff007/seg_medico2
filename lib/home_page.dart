import 'package:flutter/material.dart';

// La pagina iniziale dell'applicazione.
class HomePage extends StatelessWidget {
  // Aggiunti i parametri db e userId al costruttore.
  // Ho usato 'dynamic' per 'db' perché non conosco il tipo esatto del tuo database (es. FirebaseFirestore).
  // Assicurati di usare il tipo corretto se lo conosci.
  final dynamic db;
  final String userId;

  const HomePage({super.key, required this.db, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benvenuto', style: TextStyle(color: Colors.white)), // Titolo della barra dell'app
        backgroundColor: Colors.blueAccent, // Colore della barra dell'app
        iconTheme: const IconThemeData(color: Colors.white), // Colore dell'icona (per il drawer)
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Bordi arrotondati per la barra dell'app
          ),
        ),
      ),
      // Il Drawer è il menu laterale che si apre scorrendo da sinistra.
      drawer: Drawer(
        // Aggiunto un bordo arrotondato al Drawer per un look più moderno
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero, // Rimuove il padding predefinito
          children: <Widget>[
            // Header del Drawer, può contenere il nome dell'app o un'immagine.
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Segretario Medico',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Menu Principale',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Elemento del menu per "Appuntamenti".
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue), // Icona più evidente
              title: const Text('Appuntamenti', style: TextStyle(fontSize: 18, color: Colors.blueGrey)), // Testo
              onTap: () {
                // Chiude il drawer e naviga alla pagina Appuntamenti.
                Navigator.pop(context); // Chiude il drawer
                Navigator.pushNamed(context, '/appuntamenti'); // Naviga alla rotta
              },
            ),
            // Elemento del menu per "Farmaci".
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.green), // Icona più evidente
              title: const Text('Farmaci', style: TextStyle(fontSize: 18, color: Colors.blueGrey)), // Testo
              onTap: () {
                // Chiude il drawer e naviga alla pagina Farmaci.
                Navigator.pop(context); // Chiude il drawer
                Navigator.pushNamed(context, '/farmaci'); // Naviga alla rotta
              },
            ),
            // Puoi aggiungere altri elementi del menu qui.
            ListTile(
              leading: const Icon(Icons.person, color: Colors.orange),
              title: const Text('Pazienti', style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
              onTap: () {
                Navigator.pop(context);
                // Navigator.pushNamed(context, '/pazienti'); // Crea questa rotta e pagina nel main.dart
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.purple),
              title: const Text('Cartella Clinica', style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
              onTap: () {
                Navigator.pop(context);
                // Navigator.pushNamed(context, '/cartella_clinica'); // Crea questa rotta e pagina nel main.dart
              },
            ),
            const Divider(), // Linea separatrice
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Impostazioni', style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
              onTap: () {
                Navigator.pop(context);
                // Navigator.pushNamed(context, '/impostazioni'); // Crea questa rotta e pagina nel main.dart
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Immagine di benvenuto o logo.
            Image.network(
              'https://placehold.co/150x150/ADD8E6/000000?text=Benvenuto', // Placeholder per immagine
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 100, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Usa il menu per navigare',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            Text(
              'ID Utente: $userId', // Mostra l'ID utente per debug o informazione
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Text(
              'Tocca l\'icona in alto a sinistra per aprire il menu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
// RIMOSSE LE CLASSI AppuntamentiPage e FarmaciPage da qui.
// Ora si trovano nei loro rispettivi file: appointments_page.dart e medications_page.dart.
