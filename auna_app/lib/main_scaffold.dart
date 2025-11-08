// lib/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:bubble_bottom_bar/bubble_bottom_bar.dart'; // <-- 1. Importa el paquete correcto
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  // Tu color rosado
  final Color customSelectedColor = const Color(0xFFFFADAD);
  // Color para íconos no seleccionados (el azul oscuro de tu tema)
  final Color customIconColor = const Color(0xFF333A56);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IMPORTANTE: Quitamos 'extendBody: true'
      // Esta barra necesita un fondo sólido
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      
      // --- REEMPLAZAMOS EL BOTTOMNAVIGATIONBAR ---
      bottomNavigationBar: BubbleBottomBar(
        backgroundColor: Colors.white, // Fondo blanco sólido
        elevation: 8, // Sombra para que "flote"
        opacity: 1, // Sin transparencias
        
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index != null) { // El paquete puede devolver null
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        
        // --- Definición de las pestañas (Items) ---
        items: <BubbleBottomBarItem>[
          BubbleBottomBarItem(
            backgroundColor: customSelectedColor, // El color de la "burbuja"
            icon: Icon(
              Icons.home_outlined,
              color: customIconColor, // Color del ícono inactivo
            ),
            activeIcon: const Icon(
              Icons.home,
              color: Colors.white, // Color del ícono activo (dentro de la burbuja)
            ),
            title: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          BubbleBottomBarItem(
            backgroundColor: customSelectedColor,
            icon: Icon(
              Icons.calendar_today_outlined,
              color: customIconColor,
            ),
            activeIcon: const Icon(
              Icons.calendar_today,
              color: Colors.white,
            ),
            title: const Text('Historial', style: TextStyle(color: Colors.white)),
          ),
          BubbleBottomBarItem(
            backgroundColor: customSelectedColor,
            icon: Icon(
              Icons.settings_outlined,
              color: customIconColor,
            ),
            activeIcon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            title: const Text('Configuración', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      // --- FIN DEL REEMPLAZO ---
    );
  }
}