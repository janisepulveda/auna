// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'crisis_detail_screen.dart';
import 'user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ASSETS ---
  static const String _background = 'assets/imagenes/fondo.JPG';
  static const String _stems      = 'assets/imagenes/tallos.PNG';
  static const String _buds       = 'assets/imagenes/brotes.PNG';

  // Nomeolvides = UMBRAL LEVE (1–3)
  static const List<String> _forgetMeNotStages = [
    'assets/imagenes/nomeolvides_0.PNG',
    'assets/imagenes/nomeolvides_1.PNG',
    'assets/imagenes/nomeolvides_2.PNG',
    'assets/imagenes/nomeolvides_3.PNG',
    'assets/imagenes/nomeolvides_abiertas.PNG',
  ];

  // Margaritas = UMBRAL MODERADO (4–7)
  static const List<String> _daisyStages = [
    'assets/imagenes/margaritas_0.PNG',
    'assets/imagenes/margaritas_1.PNG',
    'assets/imagenes/margaritas_2.PNG',
    'assets/imagenes/margaritas_3.PNG',
    'assets/imagenes/margaritas_abiertas.PNG',
  ];

  // Tulipanes = UMBRAL SEVERO (8–10)
  static const List<String> _tulipStages = [
    'assets/imagenes/tulipanes_0.PNG',
    'assets/imagenes/tulipanes_1.PNG',
    'assets/imagenes/tulipanes_2.PNG',
    'assets/imagenes/tulipanes_3.PNG',
    'assets/imagenes/tulipanes_abiertos.PNG',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final allAssets = <String>[
      _background, _stems, _buds,
      ..._forgetMeNotStages,
      ..._daisyStages,
      ..._tulipStages,
    ];
    for (final path in allAssets) {
      precacheImage(AssetImage(path), context);
    }
  }

  int _stageIndex(int count) {
    if (count <= 0) return 0;
    if (count >= 4) return 4;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // -------------------------------------------------------------
        // 1. CAPAS ESTÁTICAS (Fondo, Tallos, Brotes)
        // Están fuera del Consumer para que NUNCA se muevan ni parpadeen.
        // Usamos el mismo widget alineador para todo.
        // -------------------------------------------------------------
        const _FullScreenCroppedImage(asset: _background),
        const _FullScreenCroppedImage(asset: _stems),
        const _FullScreenCroppedImage(asset: _buds),

        // -------------------------------------------------------------
        // 2. CAPAS ANIMADAS INDIVIDUALMENTE (Flores)
        // -------------------------------------------------------------
        Positioned.fill(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              // 1. Calculamos conteos
              final leve = userProvider.registeredCrises
                  .where((c) => c.intensity >= 1 && c.intensity <= 3).length;
              final moderado = userProvider.registeredCrises
                  .where((c) => c.intensity >= 4 && c.intensity <= 7).length;
              final severo = userProvider.registeredCrises
                  .where((c) => c.intensity >= 8 && c.intensity <= 10).length;

              // 2. Asignamos Assets
              final leveAsset = _forgetMeNotStages[_stageIndex(leve)];
              final moderadoAsset = _daisyStages[_stageIndex(moderado)];
              final severoAsset = _tulipStages[_stageIndex(severo)];

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Cada tipo de flor tiene su propio animador independiente.
                  // Si cambia 'leveAsset', solo esa capa hace el fade suave.
                  _AnimatedFlowerLayer(asset: leveAsset),
                  _AnimatedFlowerLayer(asset: moderadoAsset),
                  _AnimatedFlowerLayer(asset: severoAsset),
                ],
              );
            },
          ),
        ),

        // -------------------------------------------------------------
        // 3. BOTÓN FLOTANTE
        // -------------------------------------------------------------
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CrisisDetailScreen(),
                            ),
                          );
                          // El provider actualizará la UI automáticamente
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------
// WIDGETS AUXILIARES
// -----------------------------------------------------------------

/// Imagen estática a pantalla completa (Para Fondo, Tallos, Brotes)
/// Usa BoxFit.cover para garantizar que todo calce perfecto siempre.
class _FullScreenCroppedImage extends StatelessWidget {
  final String asset;
  
  // Agregamos key al constructor por si acaso
  const _FullScreenCroppedImage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        asset,
        fit: BoxFit.cover, // Mantiene tu alineación original
        alignment: Alignment.center,
        gaplessPlayback: true,
      ),
    );
  }
}

/// Capa de flor con animación suave INDIVIDUAL
class _AnimatedFlowerLayer extends StatelessWidget {
  final String asset;

  const _AnimatedFlowerLayer({required this.asset});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      // Duración lenta y relajante para el efecto "Bloom" suave
      duration: const Duration(milliseconds: 1000),
      
      // Curvas suaves
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      
      // LayoutBuilder asegura que el widget animado ocupe todo el espacio
      // y mantenga la alineación del Stack
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },

      // Solo Opacidad (Fade), sin escala para evitar desalineación visual
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      
      // Reutilizamos tu widget de imagen para garantizar que calce perfecto
      // Usamos la Key basada en el asset para que AnimatedSwitcher detecte el cambio
      child: _FullScreenCroppedImage(
        key: ValueKey(asset), 
        asset: asset,
      ),
    );
  }
}