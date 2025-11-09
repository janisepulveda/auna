// lib/main_scaffold.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // Para el ImageFilter
import 'package:google_nav_bar/google_nav_bar.dart'; // <-- 1. ¡El paquete correcto!
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
    // Detecta si el fondo actual es oscuro (como en HomeScreen)
    // Asumimos que si no es la primera pestaña (Inicio), el fondo es claro.
    bool isDarkBackground = (_selectedIndex == 0);

    return Scaffold(
      extendBody: true, // El body se extiende detrás de la barra
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            // --- ¡CAMBIO CLAVE! ---
            // El "vidrio" ahora es oscuro si el fondo es oscuro,
            // y claro si el fondo es claro.
            decoration: BoxDecoration(
              color: isDarkBackground 
                  ? const Color(0x4D000000) // Vidrio oscuro (Negro 30%)
                  : const Color(0xCCFFFFFF), // Vidrio claro (Blanco 80%)
              border: Border(
                top: BorderSide(
                  color: isDarkBackground
                      ? const Color(0x4DFFFFFF) // Borde blanco
                      : const Color(0x4D000000), // Borde negro
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                child: GNav(
                  rippleColor: customSelectedColor.withAlpha(50),
                  hoverColor: customSelectedColor.withAlpha(30),
                  gap: 8,
                  activeColor: Colors.white, // Texto/Icono dentro de la cápsula
                  iconSize: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  duration: const Duration(milliseconds: 300), // Animación
                  
                  // ¡La cápsula deslizante!
                  tabBackgroundColor: customSelectedColor, 
                  
                  // --- ¡CAMBIO CLAVE! ---
                  // El color de los íconos inactivos cambia según el fondo
                  color: isDarkBackground 
                      ? Colors.white70 // Iconos claros en fondo oscuro
                      : customIconColor,  // Iconos oscuros en fondo claro
                  
                  tabs: const [
                    GButton(
                      icon: Icons.home_outlined,
                      text: 'Inicio',
                    ),
                    GButton(
                      icon: Icons.calendar_today_outlined,
                      text: 'Historial',
                    ),
                    GButton(
                      icon: Icons.settings_outlined,
                      text: 'Configuración',
                    ),
                  ],
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}