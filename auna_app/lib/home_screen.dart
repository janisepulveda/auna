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
  // Background stages: 0..4 flowers open
  static const String _s0 = 'assets/imagenes/florero_0_abiertas.png'; // default
  static const String _s1 = 'assets/imagenes/florero_1_abierta.png';
  static const String _s2 = 'assets/imagenes/florero_2_abiertas.png';
  static const String _s3 = 'assets/imagenes/florero_3_abiertas.png';
  static const String _s4 = 'assets/imagenes/florero_4_abiertas.png';

  static const List<String> _stages = [_s0, _s1, _s2, _s3, _s4];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache all stages for smooth transitions
    for (final path in _stages) {
      precacheImage(AssetImage(path), context);
    }
  }

  int _stageIndexForCount(int crisisCount) {
    if (crisisCount <= 0) return 0;
    if (crisisCount >= 4) return 4;
    return crisisCount; // 1..3
  }

  String _assetFor(UserProvider provider) {
    final idx = _stageIndexForCount(provider.crisisCount);
    return _stages[idx];
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ["", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    const months   = ["", "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
    final now = DateTime.now();
    final formattedDate = "${weekdays[now.weekday]}, ${now.day} de ${months[now.month]}";

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen, center-aligned, cropped background that swaps per stage
        Positioned.fill(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final asset = _assetFor(userProvider);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                // IMPORTANT: child is NOT a Positioned widget
                child: _FullScreenCroppedImage(
                  key: ValueKey(asset),
                  asset: asset,
                ),
              );
            },
          ),
        ),

        // Foreground UI
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
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
                            shadows: [Shadow(blurRadius: 2.0, color: Color.fromARGB(255, 0, 0, 0))],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),

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
                            MaterialPageRoute(builder: (context) => const CrisisDetailScreen()),
                          );
                          // If crisisCount changes, AnimatedSwitcher will swap images.
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

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen, center-aligned, cropped background without using Positioned.
/// SizedBox.expand forces it to fill; BoxFit.cover scales and crops overflow.
class _FullScreenCroppedImage extends StatelessWidget {
  final String asset;
  const _FullScreenCroppedImage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.expand(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
