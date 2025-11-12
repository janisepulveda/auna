// lib/main_scaffold.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // índice actual del ítem seleccionado en la barra inferior
  int _selectedIndex = 0;

  // lista de pantallas principales disponibles en la navegación inferior
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  // color activo (rosado de flor de loto)
  final Color activeBlue = const Color(0xFFFFADAD);

  // color base para íconos y texto inactivos
  final Color iconIdle = const Color(0xFF38455C);

  // === método que construye cada ítem del menú de navegación ===
  Widget _buildNavItem({
    required IconData icon,
    required String text,
    required int index,
  }) {
    // verifica si el ítem actual está seleccionado
    final bool isSelected = (_selectedIndex == index);

    // define el color según el estado activo o inactivo
    final Color color = isSelected ? activeBlue : iconIdle.withValues(alpha: 0.8);

    return Expanded(
      child: GestureDetector(
        // al tocar, actualiza el índice seleccionado
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque, // asegura que todo el área sea tocable
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // permite que el cuerpo se extienda debajo de la barra inferior para efectos de blur
      extendBody: true,

      // cuerpo principal: muestra la pantalla correspondiente al índice seleccionado
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      // barra inferior de navegación con diseño translúcido
      bottomNavigationBar: SafeArea(
        top: false, // evita duplicar el padding superior
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: ClipRect(
            // aplica efecto glass (desenfoque)
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // configuración de tamaños y proporciones
                        const double barHeight = 80; // altura de la barra
                        const double padH = 6; // padding horizontal interno
                        const double padV = 0; // sin padding vertical para más espacio útil
                        const int count = 3; // cantidad de ítems
                        const double cellMargin = 16; // margen interno entre ítems

                        final radius = BorderRadius.circular(999);
                        final double innerW = constraints.maxWidth - padH * 2;
                        final double cellW = innerW / count;
                        final double pillW = cellW - cellMargin * 2;
                        const double pillH = barHeight - padV * 2 - (cellMargin * 2);

                        // función auxiliar para calcular posición horizontal de la cápsula
                        double leftFor(int i) => i * cellW + cellMargin;

                        return ClipRRect(
                          borderRadius: radius,
                          child: Container(
                            height: barHeight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: padH, vertical: padV),
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              // borde translúcido gris claro alrededor de la barra
                              border: Border.all(
                                color: const Color.fromARGB(123, 211, 211, 211).withValues(alpha: 0.25),
                                width: 1,
                              ),
                              // sombra sutil para destacar la barra sobre el fondo
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(123, 211, 211, 211).withValues(alpha: 0.15),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Stack(
                              children: [
                                // ===== cápsula translúcida que se mueve según el ítem activo =====
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                  top: (barHeight - padV * 2 - pillH) / 2,
                                  left: leftFor(_selectedIndex),
                                  width: pillW,
                                  height: pillH,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: const Color.fromARGB(255, 212, 212, 212)
                                                .withValues(alpha: 0.30),
                                            width: 1,
                                          ),
                                          // degradado vertical muy sutil (para dar sensación de volumen)
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color.fromARGB(255, 137, 137, 137)
                                                  .withValues(alpha: 0.12),
                                              const Color.fromARGB(255, 137, 137, 137)
                                                  .withValues(alpha: 0.00),
                                            ],
                                            stops: const [0.0, 0.7],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // ===== fila de ítems de navegación =====
                                Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: innerW,
                                    height: barHeight - padV * 2,
                                    child: Row(
                                      children: [
                                        _buildNavItem(
                                          icon: Icons.home_rounded,
                                          text: 'Home',
                                          index: 0,
                                        ),
                                        _buildNavItem(
                                          icon: Icons.calendar_today_rounded,
                                          text: 'Historial',
                                          index: 1,
                                        ),
                                        _buildNavItem(
                                          icon: Icons.settings_rounded,
                                          text: 'Ajustes',
                                          index: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
