// lib/user_provider.dart
import 'package:flutter/material.dart';

// Clase para los datos del usuario
class UserData {
  final String name;
  final String email;
  UserData({required this.name, required this.email});
}

// ¡CLASE ACTUALIZADA!
class CrisisModel {
  final DateTime date;
  final double intensity;
  final int duration;
  final String notes;
  final String trigger; // <-- ¡NUEVO!
  final List<String> symptoms; // <-- ¡NUEVO!

  CrisisModel({
    required this.date,
    required this.intensity,
    required this.duration,
    required this.notes,
    required this.trigger,    // <-- ¡NUEVO!
    required this.symptoms, // <-- ¡NUEVO!
  });
}

class UserProvider with ChangeNotifier {
  UserData? _user;
  UserData? get user => _user;

  final List<CrisisModel> _registeredCrises = [];
  List<CrisisModel> get registeredCrises => _registeredCrises;

  int get crisisCount => _registeredCrises.length;

  void login(String name, String email) {
    _user = UserData(name: name, email: email);
    notifyListeners();
  }

  void logout() {
    _user = null;
    _registeredCrises.clear();
    notifyListeners();
  }

  // ¡FUNCIÓN ACTUALIZADA!
  void registerCrisis({
    required double intensity,
    required int duration,
    required String notes,
    required String trigger,    // <-- ¡NUEVO!
    required List<String> symptoms, // <-- ¡NUEVO!
  }) {
    _registeredCrises.add(
      CrisisModel(
        date: DateTime.now(),
        intensity: intensity,
        duration: duration,
        notes: notes,
        trigger: trigger,    // <-- ¡NUEVO!
        symptoms: symptoms, // <-- ¡NUEVO!
      ),
    );
    notifyListeners();
  }
}