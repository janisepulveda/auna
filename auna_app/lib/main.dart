// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'login_screen.dart';
import 'user_provider.dart';
import 'notification_service.dart'; // <-- trae rootNavigatorKey
import 'ble_manager.dart';          // <-- registra el servicio BLE global

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa notificaciones (canales, acciones, callbacks)
  await NotificationService().init();

  // Inicializa formato de fechas (Español Chile)
  await initializeDateFormatting('es_CL', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Inyecta UserProvider dentro de BleManager para registrar crisis desde el servicio
        ChangeNotifierProxyProvider<UserProvider, BleManager>(
          create: (_) => BleManager(),
          update: (_, userProv, ble) {
            ble ??= BleManager();
            ble.userProvider = userProv;
            return ble;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auna',

      // Usa la MISMA llave global que el NotificationService
      navigatorKey: rootNavigatorKey,

      // Rutas (incluye la de edición para la acción "Editar")
      routes: {
        '/crisis/edit': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<dynamic, dynamic>?;
          final crisisId = args?['crisisId'] as String?;
          return EditCrisisScreen(crisisId: crisisId);
        },
      },

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A67D8),
          primary: const Color(0xFF333A56),
          secondary: const Color(0xFFE8E8E8),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF333A56)),
          titleTextStyle: TextStyle(
            color: Color(0xFF333A56),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF333A56),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// === Placeholder mínimo para la pantalla de edición ===
/// Reemplázala por tu pantalla real cuando quieras.
class EditCrisisScreen extends StatelessWidget {
  final String? crisisId;
  const EditCrisisScreen({super.key, this.crisisId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar crisis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Editando crisis: ${crisisId ?? "(sin id)"}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Notas'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: guarda los cambios reales en tu UserProvider o repositorio.
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
