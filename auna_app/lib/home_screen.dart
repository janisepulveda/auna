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
  // assets

  // Fondo fijo y capas estructurales
  static const String _background = 'assets/imagenes/fondo.JPG';
  static const String _stems      = 'assets/imagenes/tallos.PNG';
  static const String _buds       = 'assets/imagenes/brotes.PNG';

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
      _background,
      _stems,
      _buds,
      ..._tulipStages,
      ..._daisyStages,
      ..._forgetMeNotStages,
    ];
    for (final path in allAssets) {
      precacheImage(AssetImage(path), context);
    }
  }

    // utilidades

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
    return Stack(
      fit: StackFit.expand,
      children: [
        // fondo: capas superpuestas
        Positioned.fill(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final leve = _leveCount(userProvider);
              final moderado = _moderadoCount(userProvider);
              final severo = _severoCount(userProvider);

              final leveAsset     = _tulipStages[_stageIndex(leve)];
              final moderadoAsset = _daisyStages[_stageIndex(moderado)];
              final severoAsset   = _forgetMeNotStages[_stageIndex(severo)];

              final comboKey =
                  '$_background|$_stems|$_buds|$leveAsset|$moderadoAsset|$severoAsset';

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
                  backgroundAsset: _background,
                  stemsAsset: _stems,
                  budsAsset: _buds,
                  leveAsset: leveAsset,
                  moderadoAsset: moderadoAsset,
                  severoAsset: severoAsset,
                ),
              );
            },
          ),
        ),

        // botón flotante único (registrar crisis)
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
                              builder: (context) =>
                                  const CrisisDetailScreen(),
                            ),
                          );
                          setState(() {});
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
                            color: Colors.white, // icono blanco para contraste
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

// fondo compuesto: capas fijas + 3 capas de flores

class _FlowerBackground extends StatelessWidget {
  final String backgroundAsset;
  final String stemsAsset;
  final String budsAsset;
  final String leveAsset;
  final String moderadoAsset;
  final String severoAsset;

  const _FlowerBackground({
    super.key,
    required this.backgroundAsset,
    required this.stemsAsset,
    required this.budsAsset,
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
          _FullScreenCroppedImage(asset: backgroundAsset), // fondo verde
          _FullScreenCroppedImage(asset: stemsAsset),       // tallos
          _FullScreenCroppedImage(asset: budsAsset),        // brotes base
          _FullScreenCroppedImage(asset: leveAsset),        // tulipanes
          _FullScreenCroppedImage(asset: moderadoAsset),    // margaritas
          _FullScreenCroppedImage(asset: severoAsset),      // nomeolvides
        ],
      ),
    );
  }
}

/// Imagen a pantalla completa con recorte centrado.
class _FullScreenCroppedImage extends StatelessWidget {
  final String asset;
  const _FullScreenCroppedImage({required this.asset});

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
