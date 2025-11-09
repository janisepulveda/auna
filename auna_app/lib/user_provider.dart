// lib/user_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Importamos el paquete de IDs

var uuid = const Uuid(); // Creamos una instancia para generar IDs

class UserData {
  final String name;
  final String email;
  UserData({required this.name, required this.email});
}

class CrisisModel {
  final String id; // ID único
  final DateTime date;
  double intensity;
  int duration;
  String notes;
  String trigger;
  List<String> symptoms;

  CrisisModel({
    required this.id,
    required this.date,
    required this.intensity,
    required this.duration,
    required this.notes,
    required this.trigger,
    required this.symptoms,
  });
}

// --- ¡ASEGÚRATE QUE TENGA 'with ChangeNotifier'! ---
class UserProvider with ChangeNotifier {
  UserData? _user;
  UserData? get user => _user;

  final List<CrisisModel> _registeredCrises = [];
  List<CrisisModel> get registeredCrises => _registeredCrises;

  int get crisisCount => _registeredCrises.length;

  // Función para encontrar una crisis por su ID
  CrisisModel? getCrisisById(String id) {
    try {
      return _registeredCrises.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  void login(String name, String email) {
    _user = UserData(name: name, email: email);
    notifyListeners();
  }

  void logout() {
    _user = null;
    _registeredCrises.clear();
    notifyListeners();
  }

  // Función de registro (ahora devuelve la crisis)
  CrisisModel registerCrisis({
    required double intensity,
    required int duration,
    required String notes,
    required String trigger,
    required List<String> symptoms,
  }) {
    final newCrisis = CrisisModel(
      id: uuid.v4(), // Asigna un ID único
      date: DateTime.now(),
      intensity: intensity,
      duration: duration,
      notes: notes,
      trigger: trigger,
      symptoms: symptoms,
    );
    _registeredCrises.add(newCrisis);
    notifyListeners();
    return newCrisis; 
  }

  // Función para actualizar (editar) una crisis
  void updateCrisis({
    required String id,
    required double intensity,
    required int duration,
    required String notes,
    required String trigger,
    required List<String> symptoms,
  }) {
    final crisisIndex = _registeredCrises.indexWhere((c) => c.id == id);
    if (crisisIndex != -1) {
      _registeredCrises[crisisIndex].intensity = intensity;
      _registeredCrises[crisisIndex].duration = duration;
      _registeredCrises[crisisIndex].notes = notes;
      _registeredCrises[crisisIndex].trigger = trigger;
      _registeredCrises[crisisIndex].symptoms = symptoms;
      
      notifyListeners();
    }
  }
}