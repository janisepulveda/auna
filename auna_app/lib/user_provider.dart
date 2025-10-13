// lib/user_provider.dart
import 'package:flutter/material.dart';

// Clase para los datos del usuario
class UserData {
  final String name;
  final String email;
  UserData({required this.name, required this.email});
}

// ¡Nuevo! Una clase para guardar los datos de cada crisis
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

  // Ahora guardamos una lista detallada de crisis
  final List<CrisisModel> _registeredCrises = [];
  List<CrisisModel> get registeredCrises => _registeredCrises;

  // El contador de flores sigue funcionando, ahora basado en el largo de la lista
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

  // ¡Función mejorada! Ahora acepta todos los detalles de la crisis
  void registerCrisis({
    required double intensity,
    required int duration,
    required String notes,
  }) {
    _registeredCrises.add(
      CrisisModel(
        date: DateTime.now(), // Guarda la fecha y hora exactas
        intensity: intensity,
        duration: duration,
        notes: notes,
      ),
    );
    notifyListeners();
  }
}