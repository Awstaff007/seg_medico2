import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/main_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings _currentSettings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentSettings = Settings.fromJson(
        Provider.of<AppProvider>(context, listen: false).settings.toJson());
  }

  void _saveSettings() {
    Provider.of<AppProvider>(context, listen: false).updateSettings(_currentSettings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impostazioni salvate.')),
    );
    if(mounted) Navigator.of(context).pop();
  }

  void _showTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 Questa è una notifica di prova!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Impostazioni', textScaler: TextScaler.linear(textScaler)),
      ),
      drawer: const MainDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Generali', context),
          _buildFontSizeSetting(),
          _buildThemeSetting(themeProvider),
          const Divider(height: 32),
          _buildSectionTitle('Notifiche Farmaci', context),
          _buildDrugReminderSetting(),
          const Divider(height: 32),
          _buildSectionTitle('Notifiche Appuntamenti', context),
          _buildAppointmentDayReminderSetting(),
          _buildAppointmentTimeReminderSetting(),
          const Divider(height: 32),
          _buildSectionTitle('Permessi', context),
          ListTile(
            title: Text('Notifiche Push', textScaler: TextScaler.linear(textScaler)),
            subtitle: const Text('Tocca per aprire le impostazioni dell\'app'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Qui andrebbe la logica per aprire le impostazioni del sistema
            },
          ),
          const SizedBox(height: 32),
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
                  onPressed: _saveSettings,
                  child: Text('SALVA', textScaler: TextScaler.linear(textScaler)),
                ),
              ),
            ],
          ),
           const SizedBox(height: 16),
           Center(
             child: TextButton(
                onPressed: _showTestNotification,
                child: Text('PROVA NOTIFICA', textScaler: TextScaler.linear(textScaler)),
             ),
           )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
        textScaler: TextScaler.linear(textScaler),
      ),
    );
  }

  Widget _buildFontSizeSetting() {
    final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
    return ListTile(
      title: Text('Dimensione testo', textScaler: TextScaler.linear(textScaler)),
      subtitle: Slider(
        value: _currentSettings.fontSize,
        min: 50,
        max: 200,
        divisions: 15,
        label: '${_currentSettings.fontSize.round()}%',
        onChanged: (value) {
          setState(() {
            _currentSettings.fontSize = value;
          });
        },
      ),
      trailing: Text('${_currentSettings.fontSize.round()}%', textScaler: TextScaler.linear(textScaler)),
    );
  }

  Widget _buildThemeSetting(ThemeProvider themeProvider) {
    final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
    return ListTile(
      title: Text('Tema', textScaler: TextScaler.linear(textScaler)),
      trailing: DropdownButton<String>(
        value: _currentSettings.theme,
        items: const [
          DropdownMenuItem(value: 'system', child: Text('Sistema')),
          DropdownMenuItem(value: 'light', child: Text('Chiaro')),
          DropdownMenuItem(value: 'dark', child: Text('Scuro')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _currentSettings.theme = value;
              if (value == 'light') themeProvider.setThemeMode(ThemeMode.light);
              else if (value == 'dark') themeProvider.setThemeMode(ThemeMode.dark);
              else themeProvider.setThemeMode(ThemeMode.system);
            });
          }
        },
      ),
    );
  }

  Widget _buildDrugReminderSetting() {
    final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
    return Column(
      children: [
        SwitchListTile(
          title: Text('Avviso ripetizione farmaci', textScaler: TextScaler.linear(textScaler)),
          value: _currentSettings.drugReminderEnabled,
          onChanged: (value) {
            setState(() {
              _currentSettings.drugReminderEnabled = value;
            });
          },
        ),
        if (_currentSettings.drugReminderEnabled)
          ListTile(
            title: Text('Ripetizione ogni (giorni)', textScaler: TextScaler.linear(textScaler)),
            trailing: SizedBox(
              width: 80,
              child: DropdownButton<int>(
                isExpanded: true,
                value: _currentSettings.drugReminderDays,
                items: [15, 30, 45, 60].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _currentSettings.drugReminderDays = newValue!;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentDayReminderSetting() {
    final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
    return SwitchListTile(
      title: Text('Avviso il giorno prima', textScaler: TextScaler.linear(textScaler)),
      value: _currentSettings.appointmentDayReminderEnabled,
      onChanged: (value) {
        setState(() {
          _currentSettings.appointmentDayReminderEnabled = value;
        });
      },
    );
  }

  Widget _buildAppointmentTimeReminderSetting() {
    final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
    return Column(
      children: [
        SwitchListTile(
          title: Text('Avviso prima della visita', textScaler: TextScaler.linear(textScaler)),
          value: _currentSettings.appointmentTimeReminderEnabled,
          onChanged: (value) {
            setState(() {
              _currentSettings.appointmentTimeReminderEnabled = value;
            });
          },
        ),
        if (_currentSettings.appointmentTimeReminderEnabled)
          ListTile(
            title: Text('Avvisami (minuti prima)', textScaler: TextScaler.linear(textScaler)),
            trailing: SizedBox(
              width: 80,
              child: DropdownButton<int>(
                isExpanded: true,
                value: _currentSettings.appointmentReminderMinutes,
                items: [30, 60, 90, 120].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _currentSettings.appointmentReminderMinutes = newValue!;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
