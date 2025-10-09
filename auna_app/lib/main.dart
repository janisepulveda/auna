// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- 1. importa el paquete provider
import 'login_screen.dart';
import 'user_provider.dart'; // <-- 2. importa tu archivo user_provider

void main() {
  // 3. envuelve la aplicación con el changenotifierprovider
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(), // esto crea una única instancia de tu "tablero"
      child: const MyApp(), // ahora myapp y todas las pantallas dentro de ella pueden acceder a los datos del usuario
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // el resto de tu código aquí no necesita ningún cambio.
    return MaterialApp(
      title: 'Auna',
      theme: ThemeData(
        // ... tu tema ...
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