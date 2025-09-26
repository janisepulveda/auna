// history_screen.dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Placeholder para el calendario
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: const [
                    Text("Agosto 2025", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Icon(Icons.calendar_month, size: 150, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("Aquí irá el calendario interactivo."),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Placeholder para la lista de crisis
              Expanded(
                child: Container(
                  child: Center(
                    child: Text(
                      'Selecciona un día para ver los detalles.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}