import 'package:flutter/material.dart';

class StoricoVisiteScreen extends StatelessWidget {
  const StoricoVisiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Appuntamenti Medici'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
            const SizedBox(height: 20),
            Text(
              'Cronologia Appuntamenti Medici',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Questa sezione verrà implementata prossimamente.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}