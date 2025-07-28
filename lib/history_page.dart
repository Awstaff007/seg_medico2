// lib/history_page.dart
import 'package:flutter/material.dart';
import 'package:seg_medico2/data/database.dart';
import 'package:intl/intl.dart'; // For date formatting

class HistoryPage extends StatefulWidget {
  final AppDatabase db;
  final String userId;

  const HistoryPage({super.key, required this.db, required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late AppDatabase _db;
  late String _currentUserId;
  late Stream<List<History>> _historyStream;
  Profile? _userProfile;

  @override
  void initState() {
    super.initState();
    _db = widget.db;
    _currentUserId = widget.userId;
    _loadProfileAndHistory();
  }

  Future<void> _loadProfileAndHistory() async {
    _db.watchProfileForUser(_currentUserId).listen((profile) {
      if (profile != null) {
        setState(() {
          _userProfile = profile;
        });
      }
    });
    _historyStream = _db.watchHistoryForUser(_currentUserId); // Corrected method name
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final double fontSizeScale = _userProfile?.granularFontSizeScale ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Attività'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<History>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Nessuna attività registrata.',
                style: TextStyle(fontSize: 18 * fontSizeScale),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final historyEntries = snapshot.data!;
            // Sort by timestamp in descending order (most recent first)
            historyEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Access timestamp directly

            return ListView.builder(
              itemCount: historyEntries.length,
              itemBuilder: (context, index) {
                final entry = historyEntries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      '${_formatDateTime(entry.timestamp)} - ${entry.type.replaceAll('_', ' ')}', // Access timestamp directly
                      style: TextStyle(fontSize: 18 * fontSizeScale, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      entry.description,
                      style: TextStyle(fontSize: 16 * fontSizeScale),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}