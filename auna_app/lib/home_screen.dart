// home_screen.dart
import 'package:flutter/material.dart';
import 'crisis_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener la fecha actual para el saludo
    final String currentDate = "${DateTime.now().day} de ${[
      "", "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
    ][DateTime.now().month]}";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(currentDate, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const Text('Hola, Ana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // Placeholder para el "jardín"
            Icon(Icons.local_florist_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'Tu jardín está tranquilo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cada vez que registres una crisis, una nueva flor aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Registrar Crisis'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CrisisDetailScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}