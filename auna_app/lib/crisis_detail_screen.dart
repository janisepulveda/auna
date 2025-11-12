// lib/crisis_detail_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

/// ------------------------------------------------------------
/// glass brillante (usa .withValues para transparencias finas)
/// esta clase genera decoraciones tipo "glassmorphism" que reutilizas
/// ------------------------------------------------------------
class Glass {
  static BoxDecoration bright({
    double radius = 18,
    double borderAlpha = .6,
    double fillAlpha = .18,
  }) {
    return BoxDecoration(
      // bordes redondeados suaves
      borderRadius: BorderRadius.circular(radius),

      // borde blanco semitransparente para efecto de vidrio
      border: Border.all(color: Colors.white.withValues(alpha: borderAlpha), width: 1.2),

      // gradiente sutil que da volumen
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: fillAlpha + .1),
          Colors.white.withValues(alpha: fillAlpha),
        ],
      ),

      // sombra fría para separar del fondo
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

/// ------------------------------------------------------------
/// contenedor reutilizable con blur de fondo y estilo glass
/// úsalo como card para agrupar contenido (inputs, botones, etc.)
/// ------------------------------------------------------------
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
      // recorta el blur y el contenido al radio indicado
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        // aplica desenfoque al fondo (efecto vidrio)
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

/// ------------------------------------------------------------
/// campo de texto con estética glass
/// encapsula estilos de input coherentes con el resto de la ui
/// ------------------------------------------------------------
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
        // controlador externo para leer/escribir el valor
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,

        // estilos del input: sin bordes, tipografía sobria
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

/// ------------------------------------------------------------
/// chip con efecto glass y dos estados: seleccionado / normal
/// útil para seleccionar categorías de forma táctil y legible
/// ------------------------------------------------------------
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
    // colores base consistentes con la paleta del proyecto
    const accent = Color(0xFFFFADAD);
    const textBase = Color(0xFF38455C);

    return GestureDetector(
      onTap: onTap, // dispara el callback cuando se toca el chip
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            // animación suave entre estados seleccionado / normal
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),

              // borde translúcido para reforzar el efecto vidrio
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),

              // cambia de gradiente según el estado seleccionado
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

              // sombra dependiente del estado para jerarquía visual
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

/// ------------------------------------------------------------
/// slider de intensidad con estilo glass y etiqueta flotante
/// bloquea el estilo del slider para que coincida con la paleta
/// ------------------------------------------------------------
class IntensitySlider extends StatelessWidget {
  final double value;                // valor actual del slider (1..10)
  final ValueChanged<double> onChanged; // callback al mover el slider

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
          // ancho disponible para calcular la posición de la burbuja
          final barWidth = constraints.maxWidth;

          // normalización del valor a 0..1 (1..10 → 0..1)
          final t = ((value.clamp(1, 10)) - 1) / 9;

          // posición horizontal de la etiqueta (resta el diámetro para centrar)
          final pos = (barWidth - 40) * t;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // pista base con gradiente tenue
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

                    // slider real con colores y alturas personalizadas
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

                    // etiqueta circular que muestra el valor (no interactiva)
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

              // etiqueta de sección para claridad
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

/// ------------------------------------------------------------
/// pantalla de detalle de crisis: sirve para crear o editar registros
/// si recibe una crisis, precarga los campos y cambia el texto de acción
/// ------------------------------------------------------------
class CrisisDetailScreen extends StatefulWidget {
  // crisis opcional: si viene, estamos en modo edición
  final CrisisModel? crisisToEdit;
  
  const CrisisDetailScreen({super.key, this.crisisToEdit});

  @override
  State<CrisisDetailScreen> createState() => _CrisisDetailScreenState();
}

class _CrisisDetailScreenState extends State<CrisisDetailScreen> {
  // estado local de la pantalla
  double _intensity = 5.0;
  final _durationController = TextEditingController(text: '15');
  final _notesController = TextEditingController();

  // catálogos de opciones (desencadenantes y síntomas)
  static const _triggers = [
    'Multitudes','Trabajo','Social','Transporte','Familia','Salud','Económico','Otro'
  ];
  static const _symptoms = [
    'Taquicardia','Mareo','Sudoración','Temblor','Náuseas',
    'Dolor en el pecho','Miedo intenso','Pánico','Tensión muscular','Ansiedad',
    'Dificultad para respirar','Sensación de irrealidad',
  ];

  // ordena síntomas por largo (y luego alfabético) para mejorar legibilidad
  List<String> get _symptomsSorted {
    final list = List<String>.from(_symptoms);
    list.sort((a, b) {
      final byLen = a.length.compareTo(b.length);
      return byLen != 0 ? byLen : a.toLowerCase().compareTo(b.toLowerCase());
    });
    return list;
  }

  String? _selectedTrigger;          // desencadenante elegido
  final _selectedSymptoms = <String>{}; // conjunto de síntomas elegidos

  bool _isEditing = false; // bandera: modo edición vs creación

  @override
  void initState() {
    super.initState();

    // si recibimos una crisis, precargamos los campos para editar
    if (widget.crisisToEdit != null) {
      _isEditing = true;
      final crisis = widget.crisisToEdit!;
      _intensity = crisis.intensity;
      _durationController.text = crisis.duration.toString();
      _notesController.text = crisis.notes;
      _selectedTrigger = crisis.trigger;
      _selectedSymptoms.addAll(crisis.symptoms);
    }
  }

  @override
  void dispose() {
    // libera controladores de texto para evitar fugas de memoria
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // guarda cambios: si estamos editando, actualiza; si no, crea un registro
  void _guardar() {
    final dur = int.tryParse(_durationController.text) ?? 0;

    // validación mínima: exige desencadenante
    if (_selectedTrigger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un desencadenante.')),
      );
      return;
    }

    if (_isEditing) {
      // actualiza la crisis existente (requiere id)
      Provider.of<UserProvider>(context, listen: false).updateCrisis(
        id: widget.crisisToEdit!.id,
        intensity: _intensity,
        duration: dur,
        notes: _notesController.text,
        trigger: _selectedTrigger!,
        symptoms: _selectedSymptoms.toList(),
      );
    } else {
      // crea una nueva crisis con los datos del formulario
      Provider.of<UserProvider>(context, listen: false).registerCrisis(
        intensity: _intensity,
        duration: dur,
        notes: _notesController.text,
        trigger: _selectedTrigger!,
        symptoms: _selectedSymptoms.toList(),
      );
    }

    // vuelve a la pantalla anterior tras guardar
    Navigator.of(context).pop();
  }

  // utilitario: distribuye widgets en dos columnas con wrap
  Widget _twoColumnWrap(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: children.map((c) => SizedBox(width: w, child: c)).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // color base suave para fondo (coherente con la estética calmada)
    const bg = Color(0xFFF0F7FA);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // encabezado con título dinámico y botón de cierre
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

              // sección: intensidad (slider)
              const Text(
                'Intensidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF38455C)),
              ),
              IntensitySlider(value: _intensity, onChanged: (v) => setState(() => _intensity = v)),
              const SizedBox(height: 20),

              // sección: duración (en segundos)
              const Text(
                'Duración (segundos)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF38455C)),
              ),
              GlassField(
                controller: _durationController,
                hint: 'Ej: 15',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // sección: desencadenante (chips en dos columnas)
              const Text(
                'Desencadenante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF38455C)),
              ),
              _twoColumnWrap(_triggers.map((t) {
                return GlassChip(
                  label: t,
                  selected: _selectedTrigger == t,
                  onTap: () => setState(() => _selectedTrigger = t),
                );
              }).toList()),
              const SizedBox(height: 20),

              // sección: síntomas (chips en dos columnas)
              const Text(
                'Síntomas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF38455C)),
              ),
              _twoColumnWrap(_symptomsSorted.map((s) {
                final sel = _selectedSymptoms.contains(s);
                return GlassChip(
                  label: s,
                  selected: sel,
                  onTap: () => setState(() {
                    sel ? _selectedSymptoms.remove(s) : _selectedSymptoms.add(s);
                  }),
                );
              }).toList()),
              const SizedBox(height: 20),

              // sección: notas libres
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

              // botón de acción: guardar o actualizar según el modo
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
