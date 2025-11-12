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

  // color rosado de la paleta (marcadores y selección)
  final Color lotusPink = const Color(0xFFFFADAD);

  // color de fondo suave solicitado (azul pálido translúcido)
  final Color backgroundSoftBlue = const Color(0xFFAABEDC).withValues(alpha: 0.12);

  @override
  void initState() {
    super.initState();
    // por defecto, seleccionamos el día enfocado actual
    _selectedDay = _focusedDay;

    // inicializa formatos regionales (fechas en español chile)
    initializeDateFormatting('es_CL', null);

    // después del primer frame, sincroniza la lista de crisis del día
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

    // pequeño retardo para que el calendario aplique la selección
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showCrisisDetailSheet(selectedDay);
      }
    });
  }

  // muestra un bottom sheet con los episodios del día seleccionado
  void _showCrisisDetailSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // permite que el sheet sea alto si hay muchos ítems
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4, // altura inicial (40% de la pantalla)
          minChildSize: 0.3,     // altura mínima
          maxChildSize: 0.6,     // altura máxima
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // tirador visual para indicar que el sheet es arrastrable
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

                  // título con la fecha formateada en español
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

                  // lista de episodios del día o mensaje vacío si no hay datos
                  Expanded(
                    child: _selectedDayCrises.isEmpty
                        ? const Center(
                            child: Text('No hay episodios registrados para este día.'),
                          )
                        : ListView.builder(
                            controller: scrollController, // integra con el sheet arrastrable
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
      // aplica el fondo azul suave en toda la pantalla
      backgroundColor: backgroundSoftBlue,
      appBar: AppBar(
        title: const Text('Historial'),
        // mismo color en el appbar para continuidad visual
        backgroundColor: backgroundSoftBlue,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // calendario mensual con eventos cargados desde el provider
          TableCalendar(
            locale: 'es_CL', // localización en español (chile)
            firstDay: DateTime.utc(2020, 1, 1), // límite inferior de navegación
            lastDay: DateTime.now().add(const Duration(days: 365)), // un año hacia adelante
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,

            // indica cuál día se considera seleccionado
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

            // notifica selección de día y actualiza la lista
            onDaySelected: _onDaySelected,

            // devuelve la lista de eventos (crisis) por día para mostrar marcadores
            eventLoader: (day) {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              return userProvider.registeredCrises
                  .where((c) => isSameDay(c.date, day))
                  .toList();
            },

            // estilos del encabezado del calendario
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(fontSize: 20.0, color: Colors.black87),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
            ),

            // estilos de celdas, selección, hoy y marcadores
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.black87),
              weekendTextStyle: TextStyle(color: lotusPink.withAlpha(200)),
              outsideTextStyle: TextStyle(color: Colors.grey[400]),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: lotusPink, // resalta el día seleccionado con rosado
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: lotusPink.withAlpha(200), // color de los puntos de evento
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1, // máximo un marcador por día para no saturar
            ),
          ),
        ],
      ),
    );
  }

  // construye un ítem de la lista de episodios con hora, duración e intensidad
  Widget _buildCrisisListItem(CrisisModel crisis) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // bloque de hora y duración
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.Hm().format(crisis.date), // hora en formato 24h
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

            // bloque de barra + valor de intensidad
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

  // dibuja una barra discreta de 10 segmentos para la intensidad
  Widget _buildIntensityBar(double intensity) {
    return Row(
      children: List.generate(10, (index) {
        return Container(
          width: 8,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: index < intensity
                ? lotusPink               // segmentos activos en rosado
                : Colors.grey.shade300,    // segmentos inactivos en gris claro
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
