// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'login_screen.dart';
import 'user_provider.dart';
import 'notification_service.dart'; // servicio de notificaciones (define rootNavigatorKey)
import 'ble_manager.dart';          // servicio global para manejar bluetooth (ble)

void main() async {
  // asegura que los bindings de flutter estén listos antes de inicializar servicios asíncronos
  WidgetsFlutterBinding.ensureInitialized();

  // inicializa las notificaciones locales (canales, permisos y callbacks)
  await NotificationService().init();

  // inicializa los formatos de fecha para español de chile
  await initializeDateFormatting('es_CL', null);

  // lanza la app con múltiples providers globales (user + ble)
  runApp(
    MultiProvider(
      providers: [
        // proveedor del usuario logueado (nombre, correo, datos de crisis)
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // proveedor de bluetooth conectado al estado del usuario
        // usa proxyprovider para pasarle userProvider dinámicamente al bleManager
        ChangeNotifierProxyProvider<UserProvider, BleManager>(
          create: (_) => BleManager(),
          update: (_, userProv, ble) {
            ble ??= BleManager();
            ble.userProvider = userProv; // conecta ble con userprovider
            return ble;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// widget raíz de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auna',

      // usa la misma llave global de navegación que notificationservice
      navigatorKey: rootNavigatorKey,

      // define rutas adicionales (por ejemplo, la de edición de crisis)
      routes: {
        '/crisis/edit': (ctx) {
          // extrae argumentos enviados por la notificación
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<dynamic, dynamic>?;
          final crisisId = args?['crisisId'] as String?;
          return EditCrisisScreen(crisisId: crisisId);
        },
      },

      // tema global (colores, tipografía y estilos base)
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A67D8),
          primary: const Color(0xFF333A56),
          secondary: const Color(0xFFE8E8E8),
          brightness: Brightness.light,
        ),

        // estilo de las appbars
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

        // estilo general para inputs (campos de texto)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),

        // estilo global para botones elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF333A56),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),

      // pantalla inicial: login
      home: const LoginScreen(),

      // oculta el banner de debug
      debugShowCheckedModeBanner: false,
    );
  }
}

/// pantalla placeholder para editar una crisis
/// se activa al tocar el botón "editar" desde una notificación
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
            // muestra el id recibido (si existe)
            Text(
              'Editando crisis: ${crisisId ?? "(sin id)"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // campo de texto para editar notas
            const TextField(
              decoration: InputDecoration(labelText: 'Notas'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // botón para guardar y volver atrás
            ElevatedButton(
              onPressed: () {
                // aquí iría la lógica real de guardado (por ejemplo, actualizar userprovider)
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
