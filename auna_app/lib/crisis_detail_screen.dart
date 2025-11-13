// lib/crisis_detail_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

// ------------------------------------------------------------
// Glass brillante
// ------------------------------------------------------------
class Glass {
  static BoxDecoration bright({
    double radius = 18,
    double borderAlpha = .6,
    double fillAlpha = .18,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: borderAlpha), width: 1.2),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: fillAlpha + .1),
          Colors.white.withValues(alpha: fillAlpha),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFAABEDC).withValues(alpha: 0.25),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double blur;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blur = 16,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: Glass.bright(radius: radius),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Campo de texto sobre glass
// ------------------------------------------------------------
class GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;

  const GlassField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          color: Color(0xFF38455C),
          height: 1.25,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Chip brillante
// ------------------------------------------------------------
class GlassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const GlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFADAD);
    const textBase = Color(0xFF38455C);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.9),
                        const Color(0xFFF2B0B5).withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.38),
                        Colors.white.withValues(alpha: 0.22),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: (selected ? accent : const Color(0xFFAABEDC)).withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  height: 1.2,
                  color: selected ? Colors.white : textBase.withValues(alpha: 0.95),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Slider brillante (tu slider original)
// ------------------------------------------------------------
class IntensitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const IntensitySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final t = ((value.clamp(1, 10)) - 1) / 9;
          final pos = (barWidth - 40) * t;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.25),
                                Colors.white.withValues(alpha: 0.18),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 12,
                          activeTrackColor: const Color(0xFFF2B0B5).withValues(alpha: 0.9),
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                          thumbColor: const Color(0xFFFFADAD),
                          overlayColor: const Color(0xFFFFADAD).withValues(alpha: 0.18),
                          showValueIndicator: ShowValueIndicator.never,
                        ),
                        child: Slider(
                          min: 1,
                          max: 10,
                          divisions: 9,
                          value: (value.clamp(1, 10)).toDouble(),
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                    Positioned(
                      left: pos,
                      top: 5,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.3),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFFADAD).withValues(alpha: 0.95),
                                const Color(0xFFF2B0B5).withValues(alpha: 0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF2B0B5).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            '${value.round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Intensidad del dolor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF38455C),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------
// Pantalla Detalle de Crisis
// ------------------------------------------------------------
class CrisisDetailScreen extends StatefulWidget {
  final CrisisModel? crisisToEdit;
  
  const CrisisDetailScreen({super.key, this.crisisToEdit});

  @override
  State<CrisisDetailScreen> createState() => _CrisisDetailScreenState();
}

class _CrisisDetailScreenState extends State<CrisisDetailScreen> {
  double _intensity = 5.0;
  final _durationController = TextEditingController(text: '15');
  final _notesController = TextEditingController();

  // duración categórica
  static const _durationOptions = [
    {'label': 'Segundos', 'value': 15},
    {'label': '< 1 min', 'value': 45},
    {'label': '1–2 min', 'value': 90},
    {'label': 'Ráfagas', 'value': 120},
  ];
  String? _selectedDurationLabel;

  static const _triggers = [
    'Multitudes','Trabajo','Social','Transporte','Familia','Salud','Económico','Otro'
  ];

  // síntomas SIN los dos largos
  static const _symptoms = [
    'Taquicardia',
    'Mareo',
    'Sudoración',
    'Temblor',
    'Náuseas',
    'Dolor en el pecho',
    'Miedo intenso',
    'Pánico',
    'Tensión muscular',
    'Ansiedad',
  ];
  
  List<String> get _symptomsSorted {
    final list = List<String>.from(_symptoms);
    list.sort((a, b) {
      final byLen = a.length.compareTo(b.length);
      return byLen != 0 ? byLen : a.toLowerCase().compareTo(b.toLowerCase());
    });
    return list;
  }

  String? _selectedTrigger;
  final _selectedSymptoms = <String>{};
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.crisisToEdit != null) {
      _isEditing = true;
      final crisis = widget.crisisToEdit!;
      _intensity = crisis.intensity;
      _durationController.text = crisis.duration.toString();
      _notesController.text = crisis.notes;
      _selectedTrigger = crisis.trigger;
      _selectedSymptoms.addAll(crisis.symptoms);

      final d = crisis.duration;
      if (d <= 30) {
        _selectedDurationLabel = 'Segundos';
      } else if (d <= 60) {
        _selectedDurationLabel = '< 1 min';
      } else if (d <= 120) {
        _selectedDurationLabel = '1–2 min';
      } else {
        _selectedDurationLabel = 'Ráfagas';
      }
    } else {
      _selectedDurationLabel = 'Segundos';
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _guardar() {
    final dur = int.tryParse(_durationController.text) ?? 0;
    if (_selectedTrigger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un desencadenante.')),
      );
      return;
    }

    if (_isEditing) {
      Provider.of<UserProvider>(context, listen: false).updateCrisis(
        id: widget.crisisToEdit!.id,
        intensity: _intensity,
        duration: dur,
        notes: _notesController.text,
        trigger: _selectedTrigger!,
        symptoms: _selectedSymptoms.toList(),
      );
    } else {
      Provider.of<UserProvider>(context, listen: false).registerCrisis(
        intensity: _intensity,
        duration: dur,
        notes: _notesController.text,
        trigger: _selectedTrigger!,
        symptoms: _selectedSymptoms.toList(),
      );
    }
    Navigator.of(context).pop();
  }

  // wrap genérico en N columnas
  Widget _wrapWithColumns(List<Widget> children, {int columns = 3}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final w = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((c) => SizedBox(width: w, child: c)).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF0F7FA);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Editar Crisis' : 'Detalle de crisis',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38455C),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const GlassCard(
                      padding: EdgeInsets.all(10),
                      radius: 99,
                      blur: 10,
                      child: Icon(Icons.close, color: Color(0xFF38455C), size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // intensidad
              const Text(
                'Intensidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF38455C)),
              ),
              IntensitySlider(
                value: _intensity,
                onChanged: (v) => setState(() => _intensity = v),
              ),
              const SizedBox(height: 20),

              // duración categórica (2 columnas)
              const Text(
                'Duración aproximada del episodio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF38455C)),
              ),
              const SizedBox(height: 8),
              _wrapWithColumns(
                _durationOptions.map((opt) {
                  final label = opt['label'] as String;
                  final value = opt['value'] as int;
                  final selected = _selectedDurationLabel == label;
                  return GlassChip(
                    label: label,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _selectedDurationLabel = label;
                        _durationController.text = value.toString();
                      });
                    },
                  );
                }).toList(),
                columns: 2,
              ),
              const SizedBox(height: 20),

              // desencadenantes (3 columnas)
              const Text(
                'Desencadenante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF38455C)),
              ),
              _wrapWithColumns(
                _triggers.map((t) {
                  return GlassChip(
                    label: t,
                    selected: _selectedTrigger == t,
                    onTap: () => setState(() => _selectedTrigger = t),
                  );
                }).toList(),
                columns: 3,
              ),
              const SizedBox(height: 20),

              // síntomas (3 columnas)
              const Text(
                'Síntomas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF38455C)),
              ),
              _wrapWithColumns(
                _symptomsSorted.map((s) {
                  final sel = _selectedSymptoms.contains(s);
                  return GlassChip(
                    label: s,
                    selected: sel,
                    onTap: () => setState(() {
                      sel ? _selectedSymptoms.remove(s) : _selectedSymptoms.add(s);
                    }),
                  );
                }).toList(),
                columns: 3,
              ),
              const SizedBox(height: 20),

              // notas
              const Text(
                'Notas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF38455C)),
              ),
              GlassField(
                controller: _notesController,
                hint: 'Añade cualquier detalle que consideres importante.',
                maxLines: 4,
              ),
              const SizedBox(height: 28),

              // botón
              GestureDetector(
                onTap: _guardar,
                child: GlassCard(
                  blur: 20,
                  radius: 20,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _isEditing ? 'Actualizar Registro' : 'Guardar Registro',
                      style: const TextStyle(
                        color: Color(0xFF2E3A55),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
