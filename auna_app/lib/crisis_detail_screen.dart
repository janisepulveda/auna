// lib/crisis_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'dart:ui'; // Para el BackdropFilter

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

  final List<String> _triggers = [
    'Multitudes', 'Trabajo', 'Social', 'Transporte',
    'Familia', 'Salud', 'Económico', 'Otro'
  ];
  final List<String> _symptoms = [
    'Taquicardia', 'Mareo', 'Sudoración', 'Temblor',
    'Náuseas', 'Dificultad para respirar', 'Dolor en el pecho',
    'Sensación de irrealidad', 'Miedo intenso', 'Pánico',
    'Tensión muscular', 'Ansiedad'
  ];

  String? _selectedTrigger;
  final Set<String> _selectedSymptoms = {};

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Chip reutilizable (ahora permite múltiples líneas)
  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int maxLines = 2,                 // 👈 permite 2–3 líneas
    double minHeight = 50,            // 👈 altura mínima consistente
  }) {
    final Color selectedColor = const Color(0xFFFFADAD);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0x4DFFFFFF)),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: maxLines,
                // No usamos ellipsis: dejamos que salte de línea
                style: TextStyle(
                  height: 1.15, // un poco más compacto entre líneas
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // “Grilla” fluida de 2 columnas con Wrap
  Widget _twoColumnWrap({
    required List<Widget> children,
    double spacing = 10,
    double runSpacing = 8,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - spacing) / 2; // 2 columnas
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((w) => SizedBox(width: itemWidth, child: w))
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100.withOpacity(0.8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Detalle de crisis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white.withOpacity(0.3),
        elevation: 0,
        foregroundColor: Colors.black,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24.0,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            24.0,
            24.0,
          ),
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
                  setState(() => _intensity = value);
                },
                activeColor: const Color(0xFFFFADAD),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Duración (segundos)'),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ej: 15'),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Desencadenante'),
              _twoColumnWrap(
                children: _triggers.map((trigger) {
                  return _buildChip(
                    label: trigger,
                    isSelected: _selectedTrigger == trigger,
                    onTap: () => setState(() => _selectedTrigger = trigger),
                    maxLines: 1,       // etiquetas cortas
                    minHeight: 50,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Síntomas (selecciona todos los que apliquen)'),
              _twoColumnWrap(
                children: _symptoms.map((symptom) {
                  final isSelected = _selectedSymptoms.contains(symptom);
                  return _buildChip(
                    label: symptom,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSymptoms.remove(symptom);
                        } else {
                          _selectedSymptoms.add(symptom);
                        }
                      });
                    },
                    maxLines: 2,       // 👈 permite saltar a 2 líneas
                    minHeight: 56,     // 👈 un poco más alto para frases largas
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Notas'),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Añade cualquier detalle que consideres importante.',
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final duration = int.tryParse(_durationController.text) ?? 0;
                    final notes = _notesController.text;

                    if (_selectedTrigger == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, selecciona un desencadenante.'),
                        ),
                      );
                      return;
                    }

                    Provider.of<UserProvider>(context, listen: false)
                        .registerCrisis(
                      intensity: _intensity,
                      duration: duration,
                      notes: notes,
                      trigger: _selectedTrigger!,
                      symptoms: _selectedSymptoms.toList(),
                    );

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
      padding: const EdgeInsets.only(bottom: 8.0, top: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
