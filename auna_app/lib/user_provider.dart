// lib/user_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

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

class UserProvider with ChangeNotifier {
  UserData? _user;
  UserData? get user => _user;

  final List<CrisisModel> _registeredCrises = [];
  List<CrisisModel> get registeredCrises => _registeredCrises;

  int get crisisCount => _registeredCrises.length;

  // --- Contacto de emergencia (nuevo) ---
  String? _emergencyPhone;
  String? get emergencyPhone => _emergencyPhone;

  void setEmergencyPhone(String? phone) {
    final p = phone?.trim();
    _emergencyPhone = (p == null || p.isEmpty) ? null : p;
    notifyListeners();
  }
  // --- fin contacto emergencia ---

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

  CrisisModel registerCrisis({
    required double intensity,
    required int duration,
    required String notes,
    required String trigger,
    required List<String> symptoms,
  }) {
    final newCrisis = CrisisModel(
      id: uuid.v4(),
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

  void updateCrisis({
    required String id,
    required double intensity,
    required int duration,
    required String notes,
    required String trigger,
    required List<String> symptoms,
  }) {
    final idx = _registeredCrises.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _registeredCrises[idx].intensity = intensity;
      _registeredCrises[idx].duration = duration;
      _registeredCrises[idx].notes = notes;
      _registeredCrises[idx].trigger = trigger;
      _registeredCrises[idx].symptoms = symptoms;
      notifyListeners();
    }
  }
}
