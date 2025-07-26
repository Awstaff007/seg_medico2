import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/main_drawer.dart';

class AppuntamentiScreen extends StatefulWidget {
  const AppuntamentiScreen({Key? key}) : super(key: key);

  @override
  _AppuntamentiScreenState createState() => _AppuntamentiScreenState();
}

class _AppuntamentiScreenState extends State<AppuntamentiScreen> {
  AppointmentSlot? _selectedSlot;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchAvailableSlots();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _bookAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per favore, seleziona una data e un orario.')),
      );
      return;
    }

    final success = await Provider.of<AppProvider>(context, listen: false)
        .bookAppointment(_selectedSlot!, _notesController.text);

    if (mounted) {
        if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appuntamento prenotato con successo!')),
            );
            Navigator.of(context).pop();
        } else {
            final error = Provider.of<AppProvider>(context, listen: false).errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error ?? 'Errore durante la prenotazione.')),
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;

    return Scaffold(
      appBar: AppBar(
        title: Text('Appuntamenti', textScaler: TextScaler.linear(textScaler)),
      ),
      drawer: const MainDrawer(),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading && appProvider.availableSlots.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appProvider.errorMessage != null && appProvider.availableSlots.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  appProvider.errorMessage!,
                  textScaler: TextScaler.linear(textScaler),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disponibilità:',
                  style: Theme.of(context).textTheme.titleLarge,
                  textScaler: TextScaler.linear(textScaler),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildSlotsList(appProvider.availableSlots, textScaler),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: '✏️ Note visita (opzionale)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('ANNULLA', textScaler: TextScaler.linear(textScaler)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _bookAppointment,
                        child: Text('PRENOTA', textScaler: TextScaler.linear(textScaler)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsList(List<AppointmentSlot> slots, double textScaler) {
    if (slots.isEmpty) {
      return Center(
        child: Text(
          'Nessuna disponibilità trovata.',
          style: Theme.of(context).textTheme.bodyLarge,
          textScaler: TextScaler.linear(textScaler),
        ),
      );
    }
    
    // Group slots by date
    final Map<DateTime, List<AppointmentSlot>> groupedSlots = {};
    for (var slot in slots) {
        final dateKey = DateTime(slot.date.year, slot.date.month, slot.date.day);
        if (groupedSlots[dateKey] == null) {
            groupedSlots[dateKey] = [];
        }
        groupedSlots[dateKey]!.add(slot);
    }
    
    final sortedDates = groupedSlots.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final daySlots = groupedSlots[date]!..sort((a,b) => (a.startTime.hour * 60 + a.startTime.minute).compareTo(b.startTime.hour * 60 + b.startTime.minute));

        return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            DateFormat('EEEE d MMMM yyyy', 'it_IT').format(date),
                            style: Theme.of(context).textTheme.titleMedium,
                            textScaler: TextScaler.linear(textScaler),
                          ),
                        ),
                        Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: daySlots.map((slot) {
                                final isSelected = _selectedSlot?.id == slot.id;
                                return ChoiceChip(
                                    label: Text(slot.startTime.format(context)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                        setState(() {
                                            if (selected) {
                                                _selectedSlot = slot;
                                            }
                                        });
                                    },
                                );
                            }).toList(),
                        ),
                    ],
                ),
            ),
        );
      },
    );
  }
}
