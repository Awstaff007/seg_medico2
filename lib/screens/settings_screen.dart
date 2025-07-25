import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:segreteria_medica/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _courtesyPhraseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-popola il campo con la frase di cortesia attuale
    _courtesyPhraseController.text = Provider.of<SettingsProvider>(context, listen: false).courtesyPhrase;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sezione Dimensione Caratteri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔠 Dimensione Caratteri',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: settingsProvider.fontSizeScale,
                      min: 0.8, // Minimo 80%
                      max: 1.5, // Massimo 150%
                      divisions: 7, // 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5
                      label: '${(settingsProvider.fontSizeScale * 100).round()}%',
                      onChanged: (double value) {
                        settingsProvider.setFontSizeScale(value);
                      },
                    ),
                    Center(
                      child: Text(
                        'Dimensione attuale: ${(settingsProvider.fontSizeScale * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Sezione Frase di Cortesia
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💬 Frase di Cortesia per Ordini Farmaci',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _courtesyPhraseController,
                      decoration: const InputDecoration(
                        labelText: 'Frase di cortesia',
                        hintText: 'Es: Spett.le dott. [NomeDottore], ecco la lista...',
                      ),
                      maxLines: 3,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Usa "[NomeDottore]" come placeholder per il nome del medico.',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          settingsProvider.setCourtesyPhrase(_courtesyPhraseController.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Frase di cortesia salvata!', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
                          );
                        },
                        child: const Text('Salva Frase'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}