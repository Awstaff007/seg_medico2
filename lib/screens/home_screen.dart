import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/login_dialog.dart';
import 'package:seg_medico/widgets/main_drawer.dart';
import 'package:seg_medico/widgets/profile_dropdown.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoginDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final textScaler = appProvider.fontSizeMultiplier;

    return Scaffold(
      appBar: AppBar(
        title: const ProfileDropdown(),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Dimensione Testo',
            onPressed: () {
              showDialog(context: context, builder: (context) => const FontSizeDialog());
            },
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (appProvider.isLoggedIn && appProvider.nextAppointment != null)
                _NextAppointmentCard(
                  appointment: appProvider.nextAppointment!,
                  onCancel: () {
                     appProvider.cancelAppointment(appProvider.nextAppointment!.id);
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Visita annullata.')),
                    );
                  },
                ),
              const SizedBox(height: 24),
              _DrugReminderCard(),
              const Spacer(),
              if (!appProvider.isLoggedIn && appProvider.currentProfile != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _showLoginDialog(context),
                  child: Text(
                    'ACCEDI a ${appProvider.currentProfile!.name.toUpperCase()}',
                    textScaler: TextScaler.linear(textScaler),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                
              if (appProvider.isLoggedIn)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/farmaci'),
                        child: Text('Farmaci', textScaler: TextScaler.linear(textScaler)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/appuntamenti'),
                        child: Text('Appuntamenti', textScaler: TextScaler.linear(textScaler)),
                      ),
                    ),
                  ],
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onCancel;

  const _NextAppointmentCard({
    required this.appointment,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
     final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prossima visita: ${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(appointment.date)}',
              style: Theme.of(context).textTheme.titleMedium,
              textScaler: TextScaler.linear(textScaler),
            ),
            if (appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '↪ Note: "${appointment.notes}"',
                 textScaler: TextScaler.linear(textScaler),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: Text('Annulla visita', textScaler: TextScaler.linear(textScaler)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrugReminderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
     final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
     final settings = Provider.of<AppProvider>(context).settings;
     
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ripetizione farmaci tra ', textScaler: TextScaler.linear(textScaler)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                settings.drugReminderDays.toString(),
                style: Theme.of(context).textTheme.titleMedium,
                 textScaler: TextScaler.linear(textScaler),
              ),
            ),
            Text(' giorni', textScaler: TextScaler.linear(textScaler)),
          ],
        ),
      ),
    );
  }
}

class FontSizeDialog extends StatefulWidget {
  const FontSizeDialog({Key? key}) : super(key: key);

  @override
  _FontSizeDialogState createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<FontSizeDialog> {
  double? _currentSliderValue;

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _currentSliderValue ??= appProvider.settings.fontSize;

    return AlertDialog(
      title: const Text('Dimensione Testo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Trascina per regolare la grandezza del testo.',
            textAlign: TextAlign.center,
            textScaler: TextScaler.linear((_currentSliderValue! / 100.0)),
          ),
          Slider(
            value: _currentSliderValue!,
            min: 50,
            max: 200,
            divisions: 15,
            label: '${_currentSliderValue!.round()}%',
            onChanged: (double value) {
              setState(() {
                _currentSliderValue = value;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Annulla'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Salva'),
          onPressed: () {
            appProvider.updateFontSize(_currentSliderValue!);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
