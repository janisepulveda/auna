// lib/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'user_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CrisisModel> _selectedDayCrises = [];
  final Color lotusPink = const Color(0xFF748204);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    initializeDateFormatting('es_CL', null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSelectedDayCrises(_selectedDay!);
      }
    });
  }

  void _updateSelectedDayCrises(DateTime selectedDay) {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _selectedDayCrises = userProvider.registeredCrises.where((crisis) {
        return isSameDay(crisis.date, selectedDay);
      }).toList();
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _updateSelectedDayCrises(selectedDay);
    });

    // Pequeño delay para que la UI fluya mejor al seleccionar
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showCrisisDetailSheet(selectedDay);
      }
    });
  }

  // --- MODAL DESLIZABLE MODIFICADO ---
  void _showCrisisDetailSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite altura variable
      useSafeArea: true, // Evita que se solape con la barra de estado al expandir
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.35, // Altura inicial (35%)
          minChildSize: 0.25,    // Altura mínima al bajar
          maxChildSize: 1.0,     // CAMBIO: Permite llegar al 100% de la pantalla
          snap: true,            // CAMBIO: Se ajusta automáticamente al soltar
          snapSizes: const [0.35, 1.0], // Puntos de ajuste (Inicial y Full)
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de arrastre (Handle)
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  
                  // Título
                  Text(
                    "Episodios del ${DateFormat.yMMMMd('es_CL').format(day)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(color: Colors.black26),
                  const SizedBox(height: 8),

                  // Lista de crisis
                  Expanded(
                    child: _selectedDayCrises.isEmpty
                        ? ListView(
                            controller: scrollController, // Importante para el drag
                            children: const [
                              SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'No hay episodios registrados para este día.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                              SizedBox(height: 40),
                            ],
                          )
                        : ListView.builder(
                            controller: scrollController, // Conecta el scroll con el sheet
                            itemCount: _selectedDayCrises.length,
                            padding: const EdgeInsets.only(bottom: 20),
                            itemBuilder: (context, index) {
                              final crisis = _selectedDayCrises[index];
                              return _buildCrisisListItem(crisis);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== FONDO JPG =====
          Image.asset(
            'assets/imagenes/fondo.JPG',
            fit: BoxFit.cover,
          ),

          // ===== CONTENIDO =====
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  children: [
                    const Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
            
                    // Tarjeta del calendario
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black.withValues(alpha: 0.18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: _buildCalendar(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return TableCalendar(
      locale: 'es_CL',
      startingDayOfWeek: StartingDayOfWeek.monday,
      
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      
      rowHeight: 52, 

      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,

      eventLoader: (day) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        return userProvider.registeredCrises
            .where((c) => isSameDay(c.date, day))
            .toList();
      },

      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
      ),

      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        weekendStyle: TextStyle(
          color: lotusPink,
          fontWeight: FontWeight.w500,
        ),
      ),

      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        weekendTextStyle: TextStyle(
          color: lotusPink,
          fontWeight: FontWeight.w500,
        ),
        outsideTextStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontWeight: FontWeight.w400,
        ),
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.2,
          ),
          color: Colors.transparent,
        ),
        todayTextStyle: const TextStyle(color: Colors.white),
        selectedDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: lotusPink,
            width: 2,
          ),
          color: Colors.transparent,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        markerDecoration: BoxDecoration(
          color: lotusPink,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
      ),
    );
  }

  Widget _buildCrisisListItem(CrisisModel crisis) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.Hm().format(crisis.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // Helper para mostrar texto de duración (coherente con settings)
                Text(
                  _getDurationLabel(crisis.duration),
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _buildIntensityBar(crisis.intensity),
                const SizedBox(width: 16),
                Text(
                  crisis.intensity.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Pequeño helper para mostrar la duración en texto en la lista también
  String _getDurationLabel(int d) {
    if (d == 15) return 'Segundos';
    if (d == 45) return '< 1 min';
    if (d == 90) return '1–2 min';
    if (d == 120) return 'Ráfagas';
    return '$d min';
  }

  Widget _buildIntensityBar(double intensity) {
    return Row(
      children: List.generate(10, (index) {
        return Container(
          width: 8,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: index < intensity ? lotusPink : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}