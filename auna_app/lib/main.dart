// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'user_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'notification_service.dart'; // <-- ¡Importa el servicio!

// Hacemos que main() sea async
void main() async {
  // Asegura que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa el servicio de notificaciones
  await NotificationService().init(); 
  
  // Inicializa el formato de fecha para español
  await initializeDateFormatting('es_CL', null);
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
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
      // ¡Le damos la "llave" global a MaterialApp!
      navigatorKey: navigatorKey, 
      theme: ThemeData(
        // ... (tu tema sin cambios) ...
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
                borderSide: BorderSide.none),
            hintStyle: TextStyle(color: Colors.grey[400])),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF333A56),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        )),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}