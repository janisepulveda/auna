// lib/crisis_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart'; // Asegúrate de que este import esté presente

class CrisisDetailScreen extends StatefulWidget {
  const CrisisDetailScreen({super.key});

  @override
  CrisisDetailScreenState createState() => CrisisDetailScreenState();
}

class CrisisDetailScreenState extends State<CrisisDetailScreen> {
  double _intensity = 5.0;
  final TextEditingController _durationController =
      TextEditingController(text: '15');
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              _buildSectionTitle('Duración (segundos)'),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej: 15',
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Notas'),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Añade cualquier detalle que consideres importante.',
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 1. Leemos los valores de los campos
                    final duration = int.tryParse(_durationController.text) ?? 0;
                    final notes = _notesController.text;

                    // 2. ¡Llamamos a registerCrisis con los parámetros requeridos!
                    Provider.of<UserProvider>(context, listen: false)
                        .registerCrisis(
                      intensity: _intensity, // Pasa la intensidad
                      duration: duration,    // Pasa la duración
                      notes: notes,        // Pasa las notas
                    );

                    // 3. Cerramos la pantalla
                    Navigator.of(context).pop();
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}