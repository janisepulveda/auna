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

  // Color rosado de flor de loto
  final Color lotusPink = const Color(0xFFFFADAD);

  // Color de fondo solicitado
  final Color backgroundSoftBlue = const Color(0xFFAABEDC).withValues(alpha: 0.12);

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

  void _showCrisisDetailSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.6,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Expanded(
                    child: _selectedDayCrises.isEmpty
                        ? const Center(
                            child: Text('No hay episodios registrados para este día.'),
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
      backgroundColor: backgroundSoftBlue, // <--- Fondo azul suave con transparencia
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: backgroundSoftBlue, // <--- También en el AppBar
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'es_CL',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
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
              titleTextStyle: TextStyle(fontSize: 20.0, color: Colors.black87),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.black87),
              weekendTextStyle: TextStyle(color: lotusPink.withAlpha(200)),
              outsideTextStyle: TextStyle(color: Colors.grey[400]),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: lotusPink,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: lotusPink.withAlpha(200),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
          ),
        ],
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

  Widget _buildIntensityBar(double intensity) {
    return Row(
      children: List.generate(10, (index) {
        return Container(
          width: 8,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: index < intensity
                ? lotusPink
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
