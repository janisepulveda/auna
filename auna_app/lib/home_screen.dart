// home_screen.dart

import 'package:flutter/material.dart'; // <-- ¡ESTA ES LA LÍNEA QUE FALTABA!
import 'package:provider/provider.dart';
import 'crisis_detail_screen.dart';
import 'user_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // una lógica más completa para la fecha, incluyendo el día de la semana.
    const List<String> weekdays = ["", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    const List<String> months = ["", "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
    final DateTime now = DateTime.now();
    final String formattedDate = "${weekdays[now.weekday]}, ${now.day} de ${months[now.month]}";

    return Scaffold(
      appBar: AppBar(
        // envolvemos el título con el widget consumer.
        title: Consumer<UserProvider>(
          // el 'builder' es una función que se reconstruye cada vez que hay un cambio.
          // 'userprovider' es la instancia de tu "tablero" con los datos del usuario.
          builder: (context, userProvider, child) {

            // obtenemos el nombre del usuario del provider.
            // si el usuario no ha iniciado sesión (user es null), mostramos 'bienvenida'.
            // el '?' y '??' nos protegen de errores si el valor es nulo.
            final userName = userProvider.user?.name ?? 'Bienvenida';

            return Column(
              children: [
                Text(formattedDate, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                // usamos el nombre del usuario. '.split(' ').first' toma solo el primer nombre.
                Text(
                  'Hola, ${userName.split(' ').first}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)
                ),
              ],
            );
          },
        ),
        toolbarHeight: 80,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // placeholder para el "jardín"
            Icon(Icons.local_florist_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'Tu jardín está tranquilo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cada vez que registres una crisis, una nueva flor aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Registrar Crisis'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CrisisDetailScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}