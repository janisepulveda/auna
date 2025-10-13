// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'crisis_detail_screen.dart';
import 'user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int totalFlowers = 6;

  // lista de posiciones ajustada para subir las flores
  final List<Map<String, double>> _flowerPositions = const [
    // flores de "atrás" (más arriba y pequeñas)
    {'top': 0.44, 'left': 0.64, 'size': 50.0},
    {'top': 0.46, 'left': 0.15, 'size': 55.0},

    // flores de en medio
    {'top': 0.54, 'left': 0.70, 'size': 60.0},
    {'top': 0.60, 'left': 0.28, 'size': 65.0},
    
    // flores de "adelante" (más abajo y grandes)
    {'top': 0.70, 'left': 0.05, 'size': 70.0},
    {'top': 0.68, 'left': 0.60, 'size': 75.0},
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

                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar Crisis'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CrisisDetailScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    minimumSize: const Size(double.infinity, 50),
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