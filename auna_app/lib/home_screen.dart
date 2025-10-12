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
  // número total de flores que siempre estarán en el jardín.
  final int totalFlowers = 6;

  // ¡lista de posiciones ajustada! hemos reducido los valores de 'top' para subir las flores.
  final List<Map<String, double>> _flowerPositions = const [
    // flores de "atrás" (más arriba y pequeñas)
    {'top': 0.53, 'left': 0.55, 'size': 50.0}, 
    {'top': 0.55, 'left': 0.20, 'size': 55.0}, 

    // flores de en medio
    {'top': 0.65, 'left': 0.75, 'size': 60.0}, 
    {'top': 0.67, 'left': 0.35, 'size': 65.0}, 
    
    // flores de "adelante" (más abajo y grandes)
    {'top': 0.77, 'left': 0.15, 'size': 70.0}, 
    {'top': 0.75, 'left': 0.50, 'size': 75.0}, 
  ];

  // función para decidir qué fondo mostrar según la hora.
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
        // capa 1: fondo de pantalla.
        Image.asset(_getBackgroundImage(), fit: BoxFit.cover),
        
        // capa 2: el jardín con las 6 flores.
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final openFlowersCount = userProvider.crisisCount;

            return Stack(
              children: List.generate(
                totalFlowers, // siempre creamos 6 flores.
                (index) {
                  final position = _flowerPositions[index];
                  
                  // decidimos si esta flor debe estar abierta.
                  final bool isOpen = index < openFlowersCount;
                  
                  return FlowerWidget(
                    key: ValueKey(index), // una key única para cada flor.
                    top: screenHeight * position['top']!,
                    left: screenWidth * position['left']!,
                    size: position['size']!,
                    isOpen: isOpen, // le pasamos su estado actual (abierta o cerrada).
                  );
                },
              ),
            );
          },
        ),
        
        // capa 3: la interfaz de usuario (textos y botones).
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final userName = userProvider.user?.name ?? 'Bienvenida';
                    return Column(
                      children: [
                        Text(formattedDate, style: TextStyle(fontSize: 14, color: Colors.white70)),
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
                
                // este espacio central ahora queda vacío, permitiendo ver el jardín.
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
                // ajustamos el padding inferior para que no choque con la barra de navegación real.
                SizedBox(height: 20), 
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// widget para la flor, que ahora solo necesita saber si está abierta o cerrada.
class FlowerWidget extends StatelessWidget {
  final double top;
  final double left;
  final double size;
  final bool isOpen;

  const FlowerWidget({
    Key? key,
    required this.top,
    required this.left,
    required this.size,
    required this.isOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800), // duración de la animación de apertura.
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        // el widget que se muestra depende del estado 'isOpen'.
        child: isOpen
            ? Image.asset(
                'assets/imagenes/apertura.png',
                key: const ValueKey('open'), // una key para que el switcher sepa que el widget cambió.
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