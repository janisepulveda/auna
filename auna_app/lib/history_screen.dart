// lib/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'user_provider.dart';
import 'crisis_detail_screen.dart'; // Asegúrate de importar tu pantalla de detalle

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // _selectedDayCrises ya no es crítica para el sheet, pero la mantenemos por si la usas en otro lado
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

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showCrisisDetailSheet(selectedDay);
      }
    });
  }

  // --- SHEET DESLIZABLE REACTIVO ---
  void _showCrisisDetailSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0.35, 1.0],
          builder: (BuildContext context, ScrollController scrollController) {
            // AQUÍ ESTÁ LA SOLUCIÓN: Usamos Consumer para escuchar cambios en vivo
            return Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                // Filtramos la lista AQUÍ mismo, así siempre está fresca
                final dayCrises = userProvider.registeredCrises.where((c) {
                  return isSameDay(c.date, day);
                }).toList();

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      Expanded(
                        child: dayCrises.isEmpty
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
                                itemCount: dayCrises.length,
                                padding: const EdgeInsets.only(bottom: 20),
                                itemBuilder: (context, index) {
                                  final crisis = dayCrises[index];
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios globales para actualizar los puntitos del calendario también
    // (Opcional, pero recomendado para que todo esté sincronizado)
    Provider.of<UserProvider>(context); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/imagenes/fondo.JPG',
            fit: BoxFit.cover,
          ),
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
        titleTextStyle: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        weekendStyle: TextStyle(color: lotusPink, fontWeight: FontWeight.w500),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        weekendTextStyle: TextStyle(color: lotusPink, fontWeight: FontWeight.w500),
        outsideTextStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontWeight: FontWeight.w400),
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
          color: Colors.transparent,
        ),
        todayTextStyle: const TextStyle(color: Colors.white),
        selectedDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: lotusPink, width: 2),
          color: Colors.transparent,
        ),
        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        markerDecoration: BoxDecoration(color: lotusPink, shape: BoxShape.circle),
        markersMaxCount: 1,
      ),
    );
  }

  Widget _buildCrisisListItem(CrisisModel crisis) {
    // Detectamos si es un registro incompleto del amuleto (-1)
    final esIncompleta = crisis.intensity == -1.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: esIncompleta ? 0 : 2,
      color: esIncompleta ? Colors.grey[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esIncompleta 
            ? BorderSide(color: Colors.grey.shade400, width: 1) 
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (esIncompleta) 
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.watch_later_outlined, size: 16, color: Colors.grey),
                      ),
                    Text(
                      DateFormat.Hm().format(crisis.date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: esIncompleta ? Colors.grey[700] : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  esIncompleta ? "Solo Hora Registrada" : _getDurationLabel(crisis.duration),
                  style: TextStyle(
                    color: esIncompleta ? Colors.red[300] : Colors.black54,
                    fontWeight: esIncompleta ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            if (esIncompleta) 
              ElevatedButton.icon(
                onPressed: () {
                   // Navegación directa pasando el objeto
                   Navigator.push(
                     context, 
                     MaterialPageRoute(
                       builder: (context) => CrisisDetailScreen(crisisToEdit: crisis),
                     ),
                   );
                   // No necesitamos 'setState' aquí porque el Consumer en el sheet
                   // se encargará de actualizar la lista automáticamente al volver.
                },
                icon: const Icon(Icons.edit, size: 14),
                label: const Text("Completar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lotusPink, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                  elevation: 0,
                ),
              )
            else 
              Row(
                children: [
                  _buildIntensityBar(crisis.intensity),
                  const SizedBox(width: 12),
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