// lib/screens/cronologia_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/custom_snackbar.dart';

class CronologiaScreen extends StatefulWidget {
  const CronologiaScreen({super.key});

  @override
  State<CronologiaScreen> createState() => _CronologiaScreenState();
}

class _CronologiaScreenState extends State<CronologiaScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDateFilter;
  List<Map<String, String>> _historyItems = [];
  List<Map<String, String>> _filteredHistoryItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterHistory);
  }

  Future<void> _loadHistory() async {
    // This is mock data for now. In a real app, you'd fetch this from API/local storage.
    // For appuntamenti, you'd fetch past appointments.
    // For farmaci, you'd fetch past orders.
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    // TODO: Implementare appProvider.getAppointments() e i relativi modelli di dati
    // Placeholder per evitare l'errore di compilazione
    // final appointments = await appProvider.getAppointments();
    final List<dynamic> appointments = []; // Sostituisci con il tipo corretto una volta implementato

    List<Map<String, String>> tempHistory = [];

    // Add mock farmaci history
    tempHistory.addAll([
      {'Data': '15 Lug 2025', 'Tipo': 'Farmaco', 'Descrizione': 'Paracetamolo – febbre persistente'},
      {'Data': '08 Lug 2025', 'Tipo': 'Farmaco', 'Descrizione': 'Aspirina – dosaggio aumentato'},
    ]);

    // Add actual appointments
    for (var app in appointments) {
      final appDateTime = DateTime.parse('${app.data} ${app.inizio}');
      if (appDateTime.isBefore(DateTime.now())) { // Only show past appointments
        tempHistory.add({
          'Data': DateFormat('dd MMM yyyy').format(appDateTime),
          'Tipo': 'Appuntamento',
          'Descrizione': 'Visita in ${app.ambulatorio} alle ${app.inizio}',
        });
      }
    }

    setState(() {
      _historyItems = tempHistory;
      _filteredHistoryItems = tempHistory;
    });
  }

  void _filterHistory() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHistoryItems = _historyItems.where((item) {
        final matchesQuery = item.values.any((value) => value.toLowerCase().contains(query));
        final matchesDate = _selectedDateFilter == null ||
            DateFormat('dd MMM yyyy').parse(item['Data']!).isAtSameMomentAs(_selectedDateFilter!);
        return matchesQuery && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDateFilter) {
      setState(() {
        _selectedDateFilter = picked;
        _filterHistory();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRONOLOGIA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              CustomSnackBar.show(context, 'Funzionalità cambio dimensione caratteri non implementata.');
            },
          ),
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return DropdownButtonHideUnderline(
                child: DropdownButton<Profile>(
                  value: appProvider.selectedProfile,
                  hint: const Text('Seleziona profilo'),
                  onChanged: (Profile? newProfile) {
                    appProvider.selectProfile(newProfile);
                  },
                  items: appProvider.profiles.map((Profile profile) {
                    return DropdownMenuItem<Profile>(
                      value: profile,
                      child: Text(profile.name),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return ElevatedButton(
                onPressed: () async {
                  await appProvider.logout();
                  CustomSnackBar.show(context, 'Logout effettuato.');
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Esci'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerca nella cronologia'),
                  content: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cerca per tipo o descrizione...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Chiudi'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedDateFilter != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text('Filtro data: ${DateFormat('dd MMM yyyy').format(_selectedDateFilter!)}'),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDateFilter = null;
                        _filterHistory();
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Data')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Descrizione')),
                  ],
                  rows: _filteredHistoryItems.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item['Data']!)),
                        DataCell(Text(item['Tipo']!)),
                        DataCell(Text(item['Descrizione']!)),
                      ],
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          // Handle tap on row to open detail
                          CustomSnackBar.show(context, 'Dettaglio per: ${item['Descrizione']}');
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                if (!appProvider.isLoggedIn) {
                  CustomSnackBar.show(context, 'Accedi per accedere al menu.');
                  return;
                }
                switch (value) {
                  case 'cronologia':
                  // Already on cronologia screen
                    break;
                  case 'farmaci':
                    Navigator.pushNamed(context, '/farmaci');
                    break;
                  case 'appuntamenti':
                    Navigator.pushNamed(context, '/appuntamenti');
                    break;
                  case 'impostazioni':
                    Navigator.pushNamed(context, '/impostazioni');
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'cronologia',
                  enabled: Provider.of<AppProvider>(context).isLoggedIn,
                  child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Cronologia' : '⦿ Cronologia (dis.)'),
                ),
                PopupMenuItem<String>(
                  value: 'farmaci',
                  enabled: Provider.of<AppProvider>(context).isLoggedIn,
                  child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Farmaci' : '⦿ Farmaci (dis.)'),
                ),
                PopupMenuItem<String>(
                  value: 'appuntamenti',
                  enabled: Provider.of<AppProvider>(context).isLoggedIn,
                  child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Appuntamenti' : '⦿ Appuntamenti (dis.)'),
                ),
                PopupMenuItem<String>(
                  value: 'impostazioni',
                  enabled: Provider.of<AppProvider>(context).isLoggedIn,
                  child: Text(Provider.of<AppProvider>(context).isLoggedIn ? 'Impostazioni' : '⦿ Impostazioni (dis.)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}