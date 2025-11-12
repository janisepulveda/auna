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
  // ===== imágenes de fondo por etapa (0..4 flores abiertas) =====
  // nota: los nombres deben coincidir con tus assets en pubspec.yaml
  static const String _s0 = 'assets/imagenes/florero_0_abiertas.png'; // estado por defecto (0 flores)
  static const String _s1 = 'assets/imagenes/florero_1_abierta.png';  // 1 flor abierta
  static const String _s2 = 'assets/imagenes/florero_2_abiertas.png'; // 2 flores abiertas
  static const String _s3 = 'assets/imagenes/florero_3_abiertas.png'; // 3 flores abiertas
  static const String _s4 = 'assets/imagenes/florero_4_abiertas.png'; // 4 flores abiertas

  // lista ordenada de etapas para indexar por cantidad de crisis
  static const List<String> _stages = [_s0, _s1, _s2, _s3, _s4];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precarga todas las imágenes para evitar parpadeos al cambiar de etapa
    for (final path in _stages) {
      precacheImage(AssetImage(path), context);
    }
  }

  // traduce la cantidad de crisis a un índice de etapa (acota entre 0 y 4)
  int _stageIndexForCount(int crisisCount) {
    if (crisisCount <= 0) return 0;
    if (crisisCount >= 4) return 4;
    return crisisCount; // valores 1..3
  }

  // devuelve la ruta del asset que corresponde al estado actual del usuario
  String _assetFor(UserProvider provider) {
    final idx = _stageIndexForCount(provider.crisisCount);
    return _stages[idx];
  }

  @override
  Widget build(BuildContext context) {
    // formateo simple de fecha en español (listados locales)
    const weekdays = ["", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    const months   = ["", "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
    final now = DateTime.now();
    final formattedDate = "${weekdays[now.weekday]}, ${now.day} de ${months[now.month]}";

    return Stack(
      fit: StackFit.expand, // asegura que los hijos llenen toda la pantalla
      children: [
        // ===== fondo a pantalla completa que cambia según la etapa =====
        // se usa animatedswitcher para animar el cambio entre imágenes
        Positioned.fill(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final asset = _assetFor(userProvider);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 320), // duración de la transición
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                // animación combinada de fade + scale para suavidad
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                // importante: el child no es un positioned; eso evita errores de parentdata
                child: _FullScreenCroppedImage(
                  key: ValueKey(asset), // clave basada en el asset para disparar la animación
                  asset: asset,
                ),
              );
            },
          ),
        ),

        // ===== capa de interfaz en primer plano (segura bajo notches) =====
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
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        Text(
                          'Hola, ${userName.split(' ').first}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.white,
                            // sombra sutil para legibilidad sobre fondos claros
                            shadows: [Shadow(blurRadius: 2.0, color: Color.fromARGB(255, 0, 0, 0))],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const Spacer(), // empuja el botón hacia la parte inferior

                // botón "registrar crisis" con efecto glass (blur y borde translúcido)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF), // relleno blanco muy translúcido
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0x33FFFFFF)), // borde blanco tenue
                      ),
                      child: InkWell(
                        onTap: () async {
                          // navega a la pantalla de detalle (crear/editar)
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CrisisDetailScreen()),
                          );
                          // si cambió crisisCount, animatedswitcher actualizará el fondo
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          width: double.infinity,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Color.fromARGB(170, 0, 0, 0)),
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

                const SizedBox(height: 20), // respiración inferior para no pegar al borde
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ===== widget de imagen a pantalla completa con recorte centrado =====
/// usa:
/// - sizedbox.expand para ocupar todo el espacio disponible
/// - boxfit.cover para cubrir la pantalla y recortar si la proporción no coincide
/// - alignment.center para mantener el recorte centrado
/// - cliprect para garantizar que nada “se salga” de los bordes
class _FullScreenCroppedImage extends StatelessWidget {
  final String asset;
  const _FullScreenCroppedImage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.expand(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,       // cubre todo el viewport, recortando de ser necesario
          alignment: Alignment.center, // mantiene el foco en el centro de la imagen
          gaplessPlayback: true,   // evita parpadeo al intercambiar imágenes similares
        ),
      ),
    );
  }
}
