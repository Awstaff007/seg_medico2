import 'package:flutter/material.dart';

class DrugsScreen extends StatelessWidget {
  const DrugsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmaci')),
      body: const Center(child: Text('Pagina Farmaci')),
    );
  }
}
