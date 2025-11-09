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
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  final Color activeBlue = const Color(0xFFFFADAD); 
  final Color iconIdle = const Color(0xFF38455C);               

  //final Color _purple = const Color(0xFF6359E9);
  //final Color _red = const Color(0xFFE84C55);
  //final Color _activePillColor = const Color(0xFFB4AFFF).withOpacity(0.5); 


  Widget _buildNavItem({
    required IconData icon,
    required String text,
    required int index,
  }) {
    final bool isSelected = (_selectedIndex == index);
    final Color color = isSelected ? activeBlue : iconIdle.withValues(alpha: 0.8);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque, 
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
      extendBody: true,
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 👇 CAMBIOS AQUÍ:
                        const double barHeight = 80; // Antes 70, más alta para cápsula cuadrada
                        const double padH = 6;
                        const double padV = 0; // Antes 6, para que el contenido tenga más espacio vertical
                        const int count = 3;
                        const double cellMargin = 16; // Antes 12, más margen para hacerla más "cuadrada"

                        final radius = BorderRadius.circular(999);
                        final double innerW = constraints.maxWidth - padH * 2;
                        final double cellW = innerW / count;
                        final double pillW = cellW - cellMargin * 2;
                        final double pillH = barHeight - padV * 2 - (cellMargin * 2);

                        double leftFor(int i) => i * cellW + cellMargin;

                        return ClipRRect(
                          borderRadius: radius,
                          child: Container(
                            height: barHeight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: padH, vertical: padV),
                            decoration: BoxDecoration(
                              //gradient: LinearGradient(
                                //colors: [
                                 // _purple.withOpacity(0.35),
                                  //_red.withOpacity(0.35),
                                //],
                                //begin: Alignment.centerLeft,
                                //end: Alignment.centerRight,
                              //),
                              borderRadius: radius,
                              border: Border.all(
                                color: const Color.fromARGB(123, 211, 211, 211).withValues(alpha: 0.25),
                                width: 1,
                              ),
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
                                // ===== cápsula activa =====
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
                                      filter: ImageFilter.blur(
                                          sigmaX: 22, sigmaY: 22),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          //color: _activePillColor, 
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: const Color.fromARGB(255, 212, 212, 212).withValues(alpha: 0.30),
                                            width: 1,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color.fromARGB(255, 137, 137, 137).withValues(alpha: 0.12),
                                              const Color.fromARGB(255, 137, 137, 137).withValues(alpha: 0.00),
                                            ],
                                            stops: const [0.0, 0.7],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // ===== Ítems de navegación =====
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