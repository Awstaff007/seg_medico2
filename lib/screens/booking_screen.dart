import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/main_drawer.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  List<DateTime> _availableDates = [];
  Map<DateTime, List<String>> _availableSlots = {};

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      // Assuming getAppointmentSlots now returns Map<DateTime, List<String>> for a specific ambulatorio and numero
      // For demonstration, using dummy values for ambulatorioId and numero.
      // In a real app, these might come from user selection or be predefined.
      final availability = await appProvider.getAppointmentSlots(1, 1); // Example: ambulatorioId = 1, numero = 1
      setState(() {
        _availableDates = availability.keys.toList()..sort();
        _availableSlots = availability;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricare la disponibilità: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona una data e un orario per la prenotazione.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final selectedProfile = appProvider.selectedProfile;

      if (selectedProfile == null || selectedProfile.phoneNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilo non selezionato o numero di telefono mancante.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Extract start and end times from the selected slot string "HH:mm-HH:mm"
      final List<String> timeParts = _selectedSlot!.split('-');
      final String inizio = timeParts[0];
      final String fine = timeParts.length > 1 ? timeParts[1] : ''; // Fallback if end time is not present

      // Assuming default ambulatorioId and numero for now.
      // These should ideally be selectable or determined by the context.
      const int ambulatorioId = 1; // Placeholder
      const int numero = 1; // Placeholder

      final bool success = await appProvider.bookAppointment(
        ambulatorioId: ambulatorioId,
        numero: numero,
        data: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        inizio: inizio,
        fine: fine,
        telefono: selectedProfile.phoneNumber!,
        email: selectedProfile.email,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appuntamento prenotato con successo!')),
          );
          Navigator.of(context).pop(); // Torna alla home
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Errore durante la prenotazione dell\'appuntamento.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la prenotazione: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('APPUNTAMENTI'),
        // Removed actions for font size and profile dropdown
      ),
      drawer: MainDrawer(), // Assuming MainDrawer provides navigation
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleziona una data per il tuo appuntamento:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2,
                ),
                itemCount: _availableDates.length,
                itemBuilder: (context, index) {
                  final date = _availableDates[index];
                  final isSelected = _selectedDate == date;
                  return ChoiceChip(
                    label: Text(DateFormat('dd/MM').format(date)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDate = selected ? date : null;
                        _selectedSlot = null; // Reset slot when date changes
                      });
                    },
                  );
                },
              ),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 20),
              Text(
                'Seleziona un orario per ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _availableSlots[_selectedDate!]!
                    .map((slot) => ChoiceChip(
                  label: Text(slot),
                  selected: _selectedSlot == slot,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSlot = selected ? slot : null;
                    });
                  },
                ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Note aggiuntive (opzionale)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _selectedDate != null && _selectedSlot != null
                    ? _bookAppointment
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('PRENOTA APPUNTAMENTO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}