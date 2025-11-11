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
  static const String _closed = 'assets/imagenes/florero_0_abiertas.png';
  static const String _open   = 'assets/imagenes/florero_1_abierta.png';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache to avoid flicker on swap
    precacheImage(const AssetImage(_closed), context);
    precacheImage(const AssetImage(_open), context);
  }

  String _assetFor(UserProvider provider) =>
      (provider.crisisCount > 0) ? _open : _closed;

  @override
  Widget build(BuildContext context) {
    const weekdays = ["", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    const months   = ["", "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
    final now = DateTime.now();
    final formattedDate = "${weekdays[now.weekday]}, ${now.day} de ${months[now.month]}";

    return Stack(
      fit: StackFit.expand,
      children: [
        // Strict, full-screen, center-aligned, cropped background
        Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final asset = _assetFor(userProvider);
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) {
                // Ensure both current and previous are clipped to the screen bounds
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _FullScreenCroppedImage(
                key: ValueKey(asset),
                asset: asset,
              ),
            );
          },
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
                            shadows: [Shadow(blurRadius: 2.0, color: Colors.black45)],
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
                              Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Registrar Crisis',
                                style: TextStyle(
                                  color: Colors.white,
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

/// Renders an asset as a full-screen, center-aligned, cropped background.
/// The `ClipRect` enforces the exact screen bounds, and `SizedBox.expand` fills them.
/// `BoxFit.cover` scales the image to fully cover and crops any overflow.
class _FullScreenCroppedImage extends StatelessWidget {
  final String asset;
  const _FullScreenCroppedImage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: SizedBox.expand(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
