// lib/user_provider.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// generador de ids únicos para cada crisis
var uuid = const Uuid();

// ===== modelo simple de usuario (nombre y correo) =====
class UserData {
  final String name;
  final String email;
  UserData({required this.name, required this.email});
}

// ===== modelo de crisis (registro individual) =====
// id: identificador único
// date: fecha y hora del registro
// intensity: nivel de intensidad (1..10)
// duration: duración en segundos
// notes: notas libres del usuario
// trigger: desencadenante seleccionado
// symptoms: lista de síntomas seleccionados
class CrisisModel {
  final String id; // id único
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

// ===== provider principal del usuario y su historial =====
// expone: datos del usuario, lista de crisis, contador de crisis,
// contacto de emergencia y apis para login/logout/crear/editar crisis.
class UserProvider with ChangeNotifier {
  // estado del usuario logueado (null si no hay sesión)
  UserData? _user;
  UserData? get user => _user;

  // lista en memoria de crisis registradas
  final List<CrisisModel> _registeredCrises = [];
  List<CrisisModel> get registeredCrises => _registeredCrises;

  // contador derivado: total de crisis registradas
  int get crisisCount => _registeredCrises.length;

  // --- contacto de emergencia (teléfono opcional) ---
  String? _emergencyPhone;
  String? get emergencyPhone => _emergencyPhone;

  // guarda o limpia el teléfono de emergencia; notifica cambios
  void setEmergencyPhone(String? phone) {
    final p = phone?.trim();
    _emergencyPhone = (p == null || p.isEmpty) ? null : p;
    notifyListeners();
  }
  // --- fin contacto emergencia ---

  // busca una crisis por id; devuelve null si no existe
  CrisisModel? getCrisisById(String id) {
    try {
      return _registeredCrises.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // inicia sesión configurando nombre y correo
  void login(String name, String email) {
    _user = UserData(name: name, email: email);
    notifyListeners();
  }

  // cierra sesión y limpia el historial local
  void logout() {
    _user = null;
    _registeredCrises.clear();
    notifyListeners();
  }

  // crea y agrega un nuevo registro de crisis; devuelve el modelo creado
  CrisisModel registerCrisis({
    required double intensity,
    required int duration,
    required String notes,
    required String trigger,
    required List<String> symptoms,
  }) {
    final newCrisis = CrisisModel(
      id: uuid.v4(),               // genera id único
      date: DateTime.now(),        // registra la fecha actual
      intensity: intensity,
      duration: duration,
      notes: notes,
      trigger: trigger,
      symptoms: symptoms,
    );
    _registeredCrises.add(newCrisis);
    notifyListeners();             // avisa a la ui para refrescar
    return newCrisis;
  }

  // actualiza campos de una crisis existente por id (si la encuentra)
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
      notifyListeners();           // avisa a la ui para refrescar
    }
  }
}
