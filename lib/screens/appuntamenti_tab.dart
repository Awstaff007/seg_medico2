import 'package:flutter/material.dart';

class AppuntamentiTab extends StatelessWidget {
  final Color backgroundColor; // Proprietà per il colore di sfondo

  const AppuntamentiTab({super.key, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container( // Usa un Container per impostare il colore di sfondo
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
            const SizedBox(height: 20),
            Text(
              'Scheda Appuntamenti',
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