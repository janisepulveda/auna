// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'crisis_detail_screen.dart';
import 'user_provider.dart';
import 'dart:ui'; // <-- ¡ASEGÚRATE DE QUE ESTE IMPORT ESTÉ AQUÍ!

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int totalFlowers = 6;

  // Tu lista de posiciones (con el último ajuste para subirlas)
  final List<Map<String, double>> _flowerPositions = const [
    {'top': 0.48, 'left': 0.64, 'size': 50.0},
    {'top': 0.47, 'left': 0.15, 'size': 55.0},
    {'top': 0.55, 'left': 0.75, 'size': 60.0},
    {'top': 0.58, 'left': 0.28, 'size': 65.0},
    {'top': 0.68, 'left': 0.05, 'size': 70.0},
    {'top': 0.66, 'left': 0.60, 'size': 75.0},
  ];

  String _getBackgroundImage() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 17) {
      return 'assets/imagenes/dia.png';
    } else if (hour >= 17 && hour < 20) {
      return 'assets/imagenes/tarde.png';
    } else {
      return 'assets/imagenes/noche.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    const List<String> weekdays = ["", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    const List<String> months = ["", "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
    final DateTime now = DateTime.now();
    final String formattedDate = "${weekdays[now.weekday]}, ${now.day} de ${months[now.month]}";

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_getBackgroundImage(), fit: BoxFit.cover),
        
        // Jardín de flores
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final openFlowersCount = userProvider.crisisCount;
            return Stack(
              children: List.generate(
                totalFlowers,
                (index) {
                  final position = _flowerPositions[index];
                  final bool isOpen = index < openFlowersCount;
                  
                  return FlowerWidget(
                    key: ValueKey(index),
                    top: screenHeight * position['top']!,
                    left: screenWidth * position['left']!,
                    size: position['size']!,
                    isOpen: isOpen,
                  );
                },
              ),
            );
          },
        ),
        
        // Interfaz de usuario
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Saludo
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final userName = userProvider.user?.name ?? 'Bienvenida';
                    return Column(
                      children: [
                        Text(formattedDate, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                        Text(
                          'Hola, ${userName.split(' ').first}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 2.0, color: Colors.black45)]
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const Spacer(),

                // Botón "Liquid Glass"
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CrisisDetailScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
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

// FlowerWidget (sin cambios)
class FlowerWidget extends StatelessWidget {
  final double top;
  final double left;
  final double size;
  final bool isOpen;

  const FlowerWidget({
    super.key,
    required this.top,
    required this.left,
    required this.size,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: isOpen
            ? Image.asset(
                'assets/imagenes/apertura.png',
                key: const ValueKey('open'),
                height: size,
              )
            : Image.asset(
                'assets/imagenes/recogimiento.png',
                key: const ValueKey('closed'),
                height: size,
              ),
      ),
    );
  }
}