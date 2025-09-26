// crisis_detail_screen.dart
import 'package:flutter/material.dart';

class CrisisDetailScreen extends StatefulWidget {
  const CrisisDetailScreen({super.key});

  @override
  _CrisisDetailScreenState createState() => _CrisisDetailScreenState();
}

class _CrisisDetailScreenState extends State<CrisisDetailScreen> {
  double _intensity = 5.0; // Valor inicial para la intensidad
  final TextEditingController _durationController = TextEditingController(text: '15');
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de crisis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Para ocultar el teclado al tocar fuera
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de intensidad
              _buildSectionTitle('Intensidad'),
              Slider(
                value: _intensity,
                min: 0,
                max: 10,
                divisions: 10,
                label: _intensity.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _intensity = value;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              
              // Duración
              _buildSectionTitle('Duración (segundos)'),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej: 15',
                ),
              ),
              const SizedBox(height: 24),
              
              // Notas
              _buildSectionTitle('Notas'),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Añade cualquier detalle que consideres importante.',
                ),
              ),
              const SizedBox(height: 40),
              
              // Botón de Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Aquí iría la lógica para guardar los datos
                    Navigator.of(context).pop(); // Regresa a la pantalla anterior
                  },
                  child: const Text('Guardar Registro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para los títulos de sección
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}