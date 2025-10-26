// lib/user_provider.dart
import 'package:flutter/material.dart';

// Clase para los datos del usuario (esta ya la tenías)
class UserData {
  final String name;
  final String email;
  UserData({required this.name, required this.email});
}

// ¡Añadimos la clase para guardar los datos de cada crisis!
class CrisisModel {
  final DateTime date;
  final double intensity;
  final int duration;
  final String notes;

  CrisisModel({
    required this.date,
    required this.intensity,
    required this.duration,
    required this.notes,
  });
}

class UserProvider with ChangeNotifier {
  UserData? _user;
  UserData? get user => _user;

  // ¡Cambiamos el contador por una lista detallada!
  final List<CrisisModel> _registeredCrises = [];
  List<CrisisModel> get registeredCrises => _registeredCrises;

  // El contador de flores sigue funcionando, basado en la lista.
  int get crisisCount => _registeredCrises.length;

  void login(String name, String email) {
    _user = UserData(name: name, email: email);
    notifyListeners();
  }

  void logout() {
    _user = null;
    _registeredCrises.clear(); // Limpiamos la lista al cerrar sesión
    notifyListeners();
  }

  // ¡Función mejorada! Ahora pide y guarda los detalles en la lista.
  void registerCrisis({
    required double intensity,
    required int duration,
    required String notes,
  }) {
    _registeredCrises.add(
      CrisisModel(
        date: DateTime.now(), // Guarda la fecha y hora
        intensity: intensity,
        duration: duration,
        notes: notes,
      ),
    );
    notifyListeners();
  }
}