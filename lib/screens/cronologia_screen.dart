import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/main_drawer.dart';

class CronologiaScreen extends StatefulWidget {
  const CronologiaScreen({Key? key}) : super(key: key);

  @override
  _CronologiaScreenState createState() => _CronologiaScreenState();
}

class _CronologiaScreenState extends State<CronologiaScreen> {
  final _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final textScaler = appProvider.fontSizeMultiplier;

    final filteredHistory = appProvider.history.where((entry) {
      final searchLower = _searchController.text.toLowerCase();
      final matchesSearch = entry.description.toLowerCase().contains(searchLower) ||
          entry.type.toLowerCase().contains(searchLower);
      final matchesDate = _selectedDate == null ||
          (entry.date.year == _selectedDate!.year &&
              entry.date.month == _selectedDate!.month &&
              entry.date.day == _selectedDate!.day);
      return matchesSearch && matchesDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cronologia', textScaler: TextScaler.linear(textScaler)),
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cerca...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  tooltip: 'Filtra per data',
                  onPressed: () => _selectDate(context),
                ),
                if (_selectedDate != null)
                  ActionChip(
                    avatar: const Icon(Icons.clear),
                    label: Text(DateFormat('d/M/y').format(_selectedDate!)),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                  )
              ],
            ),
          ),
          Expanded(
            child: appProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? Center(child: Text('Nessun risultato trovato.', textScaler: TextScaler.linear(textScaler)))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          columns: [
                            DataColumn(label: Text('Data', textScaler: TextScaler.linear(textScaler))),
                            DataColumn(label: Text('Tipo', textScaler: TextScaler.linear(textScaler))),
                            DataColumn(label: Text('Descrizione', textScaler: TextScaler.linear(textScaler))),
                          ],
                          rows: filteredHistory.map((entry) {
                            return DataRow(cells: [
                              DataCell(Text(DateFormat('dd MMM yyyy', 'it_IT').format(entry.date), textScaler: TextScaler.linear(textScaler))),
                              DataCell(Text(entry.type, textScaler: TextScaler.linear(textScaler))),
                              DataCell(
                                SizedBox(
                                  width: 250, 
                                  child: Text(entry.description, overflow: TextOverflow.ellipsis, maxLines: 2, textScaler: TextScaler.linear(textScaler)),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
