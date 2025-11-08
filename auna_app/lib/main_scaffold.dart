// lib/main_scaffold.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // <-- 1. IMPORTA ESTO para el ImageFilter
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Permite que el body (tu jardín) se dibuje detrás de la barra
      extendBody: true,

      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      bottomNavigationBar: ClipRect( // Corta el efecto de desenfoque
        child: BackdropFilter( // Aplica el desenfoque
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: BottomNavigationBar(
            backgroundColor: Colors.white.withOpacity(0.1), // Tinte translúcido
            elevation: 0, // Sin sombra
            
            // Tus items (sin cambios)
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Historial',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Configuración',
              ),
            ],
            currentIndex: _selectedIndex,
            
            // Ajustamos colores para que se lean bien sobre el fondo
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70, 
            
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}