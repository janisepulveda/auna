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
  // día actualmente enfocado por el calendario
  DateTime _focusedDay = DateTime.now();

  // día seleccionado por el usuario (puede ser nulo al inicio)
  DateTime? _selectedDay;

  // lista de crisis filtradas para el día seleccionado
  List<CrisisModel> _selectedDayCrises = [];

  // verde-amarillo de los domingos / sábados
  final Color lotusPink = const Color(0xFF748204);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // inicializa formatos regionales (fechas en español chile)
    initializeDateFormatting('es_CL', null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSelectedDayCrises(_selectedDay!);
      }
    });
  }

  // actualiza la lista de crisis correspondientes a un día específico
  void _updateSelectedDayCrises(DateTime selectedDay) {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _selectedDayCrises = userProvider.registeredCrises.where((crisis) {
        return isSameDay(crisis.date, selectedDay);
      }).toList();
    });
  }

  // callback del calendario cuando el usuario selecciona un día
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _updateSelectedDayCrises(selectedDay);
    });

    // pequeño delay para que se vea primero la selección
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showCrisisDetailSheet(selectedDay);
      }
    });
  }

  // bottom sheet con los episodios del día
  void _showCrisisDetailSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // para ver el borde redondeado
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.35, // altura inicial
          minChildSize: 0.25,     // mínimo
          maxChildSize: 0.95,     // CASI pantalla completa al arrastrar
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // tirador
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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

                  // IMPORTANTE: siempre un widget scrolleable con el scrollController
                  Expanded(
                    child: _selectedDayCrises.isEmpty
                        ? ListView(
                            controller: scrollController,
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
                            controller: scrollController,
                            itemCount: _selectedDayCrises.length,
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
      // dejamos transparente para que se vea el fondo
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== FONDO JPG A PANTALLA COMPLETA =====
          Image.asset(
            'assets/imagenes/fondo.JPG', // ojo con mayúsculas en pubspec
            fit: BoxFit.cover,
          ),

          // ===== CONTENIDO =====
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0), // Bottom padding removed here to use margin inside
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

                  // tarjeta "glass" con el calendario (sin height fija)
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        // 👇 AQUÍ ESTÁ EL ARREGLO: Margin inferior para que flote
                        margin: const EdgeInsets.only(bottom: 24),
                        
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
                    ),
                  ),
                ],
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
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      
      // Ajustamos altura de filas para que sea compacto
      rowHeight: 42, 

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

      // nombres de los días de la semana
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
        // días normales
        defaultTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        // sábados y domingos
        weekendTextStyle: TextStyle(
          color: lotusPink,
          fontWeight: FontWeight.w500,
        ),
        // días de otros meses
        outsideTextStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontWeight: FontWeight.w400,
        ),

        // día de hoy: borde blanco sutil
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.2,
          ),
          color: Colors.transparent,
        ),
        todayTextStyle: const TextStyle(color: Colors.white),

        // selección: círculo SOLO CON BORDE verde-amarillo
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

        // marcadores de eventos
        markerDecoration: BoxDecoration(
          color: lotusPink,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
      ),
    );
  }

  // tarjeta de episodio individual
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
                Text(
                  '${crisis.duration} min',
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

  // barra de intensidad
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