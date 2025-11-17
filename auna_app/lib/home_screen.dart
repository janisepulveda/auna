// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'crisis_detail_screen.dart';
import 'user_provider.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // RUTAS DE ASSETS — AJUSTA ESTOS NOMBRES A TUS ARCHIVOS
  // ============================================================

  // Fondo base y tallos (siempre visibles)
  static const String _backgroundAsset = 'assets/imagenes/fondo.JPG';
  static const String _stemsAsset = 'assets/imagenes/tallos.PNG';

  // Los números indican cuántas flores abiertas se ven (0..4)

  // Tulipanes = umbral LEVE (intensidad 1–3)
  static const List<String> _tulipStages = [
    'assets/imagenes/tulipanes_0.PNG',
    'assets/imagenes/tulipanes_1.PNG',
    'assets/imagenes/tulipanes_2.PNG',
    'assets/imagenes/tulipanes_3.PNG',
    'assets/imagenes/tulipanes_abiertos.PNG',
  ];

  // Margaritas = umbral MODERADO (intensidad 4–7)
  static const List<String> _daisyStages = [
    'assets/imagenes/margaritas_0.PNG',
    'assets/imagenes/margaritas_1.PNG',
    'assets/imagenes/margaritas_2.PNG',
    'assets/imagenes/margaritas_3.PNG',
    'assets/imagenes/margaritas_abiertas.PNG',
  ];

  // Nomeolvides = umbral SEVERO (intensidad 8–10)
  static const List<String> _forgetMeNotStages = [
    'assets/imagenes/nomeolvides_0.PNG',
    'assets/imagenes/nomeolvides_1.PNG',
    'assets/imagenes/nomeolvides_2.PNG',
    'assets/imagenes/nomeolvides_3.PNG',
    'assets/imagenes/nomeolvides_abiertas.PNG',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precargamos TODAS las capas para evitar parpadeos
    final allAssets = <String>[
      _backgroundAsset,
      _stemsAsset,
      ..._tulipStages,
      ..._daisyStages,
      ..._forgetMeNotStages,
    ];
    for (final path in allAssets) {
      precacheImage(AssetImage(path), context);
    }
  }

  // ------------------------------------------------------------
  // Utilidades: contar crisis por umbral de intensidad
  // ------------------------------------------------------------

  // clamp 0..4 para indexar las listas
  int _stageIndex(int count) {
    if (count <= 0) return 0;
    if (count >= 4) return 4;
    return count;
  }

  int _leveCount(UserProvider provider) {
    return provider.registeredCrises
        .where((c) => c.intensity >= 1 && c.intensity <= 3)
        .length;
  }

  int _moderadoCount(UserProvider provider) {
    return provider.registeredCrises
        .where((c) => c.intensity >= 4 && c.intensity <= 7)
        .length;
  }

  int _severoCount(UserProvider provider) {
    return provider.registeredCrises
        .where((c) => c.intensity >= 8 && c.intensity <= 10)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    // formateo simple de fecha en español
    const weekdays = [
      "",
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo"
    ];
    const months = [
      "",
      "enero",
      "febrero",
      "marzo",
      "abril",
      "mayo",
      "junio",
      "julio",
      "agosto",
      "septiembre",
      "octubre",
      "noviembre",
      "diciembre"
    ];
    final now = DateTime.now();
    final formattedDate =
        "${weekdays[now.weekday]}, ${now.day} de ${months[now.month]}";

    return Stack(
      fit: StackFit.expand,
      children: [
        // ===== FONDO: 5 CAPAS SUPERPUESTAS =====
        // fondo + tallos + 3 tipos de flores por umbral
        Positioned.fill(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final leve = _leveCount(userProvider);
              final moderado = _moderadoCount(userProvider);
              final severo = _severoCount(userProvider);

              final leveAsset = _tulipStages[_stageIndex(leve)];
              final moderadoAsset = _daisyStages[_stageIndex(moderado)];
              final severoAsset =
                  _forgetMeNotStages[_stageIndex(severo)];

              final comboKey =
                  '$_backgroundAsset|$_stemsAsset|$leveAsset|$moderadoAsset|$severoAsset';

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1.0)
                          .animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _FlowerBackground(
                  key: ValueKey(comboKey),
                  backgroundAsset: _backgroundAsset,
                  stemsAsset: _stemsAsset,
                  leveAsset: leveAsset,
                  moderadoAsset: moderadoAsset,
                  severoAsset: severoAsset,
                ),
              );
            },
          ),
        ),

        // ===== INTERFAZ EN PRIMER PLANO =====
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // saludo superior con fecha y nombre del usuario
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final userName = userProvider.user?.name ?? 'Bienvenida';
                    return Column(
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white70),
                        ),
                        Text(
                          'Hola, ${userName.split(' ').first}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 2.0,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const Spacer(),

                // botón "Registrar crisis"
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CrisisDetailScreen(),
                            ),
                          );
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          width: double.infinity,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,
                                  color: Color.fromARGB(170, 0, 0, 0)),
                              SizedBox(width: 8),
                              Text(
                                'Registrar Crisis',
                                style: TextStyle(
                                  color: Color(0xFF38455C),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Fondo compuesto: fondo + tallos + 3 capas de flores
// ============================================================

class _FlowerBackground extends StatelessWidget {
  final String backgroundAsset;
  final String stemsAsset;
  final String leveAsset;
  final String moderadoAsset;
  final String severoAsset;

  const _FlowerBackground({
    super.key,
    required this.backgroundAsset,
    required this.stemsAsset,
    required this.leveAsset,
    required this.moderadoAsset,
    required this.severoAsset,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _FullScreenCroppedImage(asset: backgroundAsset), // fondo
          _FullScreenCroppedImage(asset: stemsAsset),       // tallos
          _FullScreenCroppedImage(asset: leveAsset),        // tulipanes
          _FullScreenCroppedImage(asset: moderadoAsset),    // margaritas
          _FullScreenCroppedImage(asset: severoAsset),      // nomeolvides
        ],
      ),
    );
  }
}

/// Imagen a pantalla completa con recorte centrado.
/// IMPORTANTE: Todas las imágenes deben tener el mismo tamaño de lienzo.
class _FullScreenCroppedImage extends StatelessWidget {
  final String asset;
  const _FullScreenCroppedImage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
      ),
    );
  }
}
