// lib/main_scaffold.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // Para el ImageFilter
import 'package:google_nav_bar/google_nav_bar.dart'; // <-- 1. Importa el nuevo paquete
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

  // Definimos tu color rosado personalizado
  final Color customSelectedColor = const Color(0xFFFFADAD);
  // Color para los íconos no seleccionados (usamos el primario de tu tema)
  final Color customIconColor = const Color(0xFF333A56); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Mantenemos esto para el efecto "liquid glass"
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      
      // --- REEMPLAZAMOS EL BOTTOMNAVIGATIONBAR ---
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            // El contenedor de vidrio que ya tenías
            decoration: BoxDecoration(
              color: const Color(0xCCFFFFFF), // Blanco ~80% opacidad
              border: Border(
                top: BorderSide(
                  color: const Color(0x4DFFFFFF), // Blanco 30%
                  width: 0.5,
                ),
              ),
            ),
            // SafeArea para evitar que los íconos queden debajo de la barra de inicio
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                child: GNav(
                  // --- ESTILO DE GNAV ---
                  rippleColor: customSelectedColor.withAlpha(50), // Color del "splash"
                  hoverColor: customSelectedColor.withAlpha(30),  // Color al pasar el mouse
                  gap: 8, // Espacio entre ícono y texto
                  activeColor: Colors.white, // Color del texto e ícono DENTRO de la cápsula
                  iconSize: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding de la cápsula
                  duration: const Duration(milliseconds: 300), // Velocidad de la animación
                  
                  // ¡LA MAGIA! Define el color de la cápsula deslizante
                  tabBackgroundColor: customSelectedColor, 
                  
                  // Color de los íconos NO seleccionados
                  color: customIconColor, 
                  
                  // Definición de las pestañas
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
      // --- FIN DEL REEMPLAZO ---
    );
  }
}