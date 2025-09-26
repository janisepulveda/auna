// main.dart
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Importa la nueva pantalla de login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auna',
      theme: ThemeData(
        // Define un tema visual 
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', // Puedes cambiar esto a una fuente personalizada
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A67D8), // Un color base
          primary: const Color(0xFF333A56), // Color para elementos principales
          secondary: const Color(0xFFE8E8E8), // Color para fondos de tarjetas/botones
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
            ),
        ),
      ),
      home: const LoginScreen(), // La app ahora empieza en la pantalla de Login
      debugShowCheckedModeBanner: false,
    );
  }
}