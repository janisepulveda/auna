// lib/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Necesario para inicializar 'intl'
import 'user_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CrisisModel> _selectedDayCrises = []; // Lista para guardar las crisis del día

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    initializeDateFormatting('es_CL', null);
    // Cargamos las crisis del día actual al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedDayCrises(_selectedDay!);
    });
  }

  // Función para obtener las crisis del día seleccionado desde el Provider
  void _updateSelectedDayCrises(DateTime selectedDay) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _selectedDayCrises = userProvider.registeredCrises.where((crisis) {
        return isSameDay(crisis.date, selectedDay);
      }).toList();
    });
  }

  // Qué hacer cuando se toca un día en el calendario
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _updateSelectedDayCrises(selectedDay); // Actualiza la lista de crisis
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: Column(
        children: [
          // --- CALENDARIO ---
          TableCalendar(
            locale: 'es_CL',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            // Marcador de eventos (puntitos en los días con crisis)
            eventLoader: (day) {
               // Necesitamos leer el provider aquí para los marcadores
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              return userProvider.registeredCrises.where((c) => isSameDay(c.date, day)).toList();
            },
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(fontSize: 20.0),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration( // Estilo de los puntitos
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
               markersMaxCount: 1, // Muestra solo un punto aunque haya varias crisis
            ),
          ),
          // --- FIN DEL CALENDARIO ---

          const SizedBox(height: 16),
          const Divider(indent: 16, endIndent: 16),

          // --- LISTA DE CRISIS DEL DÍA SELECCIONADO ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text( // Mostramos la fecha seleccionada como título
              "Episodios de dolor ${DateFormat.yMMMMd('es_CL').format(_selectedDay ?? DateTime.now())}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDayCrises.isEmpty
                // Mensaje si no hay crisis
                ? Center(
                    child: Text(
                      'No hay episodios de dolor registrados para este día.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                // Lista si hay crisis
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _selectedDayCrises.length,
                    itemBuilder: (context, index) {
                      final crisis = _selectedDayCrises[index];
                      // Usamos el widget que ya teníamos para mostrar cada crisis
                      return _buildCrisisListItem(crisis);
                    },
                  ),
          ),
        ],
      ),
    );
  }

   // Widget para mostrar cada item de la lista de crisis (lo copiamos de la versión anterior)
  Widget _buildCrisisListItem(CrisisModel crisis) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Columna para la hora y duración
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.Hm().format(crisis.date), // Formato 24h
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('${crisis.duration} min'),
              ],
            ),
            const Spacer(),
            // Columna para la barra de intensidad y el número
            Row(
              children: [
                _buildIntensityBar(crisis.intensity),
                const SizedBox(width: 16),
                Text(
                  crisis.intensity.toInt().toString(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Widget para la barra de intensidad visual (lo copiamos de la versión anterior)
  Widget _buildIntensityBar(double intensity) {
    return Row(
      children: List.generate(10, (index) {
        return Container(
          width: 8,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: index < intensity
                ? Theme.of(context).colorScheme.primary // Usamos el color primario del tema
                : Colors.grey.shade300, // Color para las barras vacías
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}