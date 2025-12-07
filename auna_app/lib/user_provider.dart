// lib/user_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importante para guardar
import 'dart:convert'; // Importante para convertir datos

// generador de ids únicos para cada crisis
var uuid = const Uuid();

// modelo simple de usuario (nombre y correo)
class UserData {
  final String name;
  final String email;
  UserData({required this.name, required this.email});

  // Convertir a JSON para guardar
  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
  };

  // Crear desde JSON al cargar
  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    name: json['name'],
    email: json['email'],
  );
}

// modelo de crisis
class CrisisModel {
  final String id;
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

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'intensity': intensity,
    'duration': duration,
    'notes': notes,
    'trigger': trigger,
    'symptoms': symptoms,
  };

  // Crear desde JSON
  factory CrisisModel.fromJson(Map<String, dynamic> json) => CrisisModel(
    id: json['id'],
    date: DateTime.parse(json['date']),
    intensity: json['intensity'],
    duration: json['duration'],
    notes: json['notes'],
    trigger: json['trigger'],
    symptoms: List<String>.from(json['symptoms']),
  );
}

class UserProvider with ChangeNotifier {
  UserData? _user;
  UserData? get user => _user;

  List<CrisisModel> _registeredCrises = [];
  List<CrisisModel> get registeredCrises => _registeredCrises;

  int get crisisCount => _registeredCrises.length;

  String? _emergencyPhone;
  String? get emergencyPhone => _emergencyPhone;

  // --- PERSISTENCIA: Cargar datos al iniciar ---
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Cargar Usuario
    final String? userJson = prefs.getString('userData');
    if (userJson != null) {
      _user = UserData.fromJson(jsonDecode(userJson));
    }

    // 2. Cargar Crisis
    final List<String> crisesJson = prefs.getStringList('registeredCrises') ?? [];
    _registeredCrises = crisesJson
        .map((str) => CrisisModel.fromJson(jsonDecode(str)))
        .toList();

    // 3. Cargar Teléfono
    _emergencyPhone = prefs.getString('emergencyPhone');
    
    notifyListeners();
  }

  // --- PERSISTENCIA: Guardar datos ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Usuario
    if (_user != null) {
      await prefs.setString('userData', jsonEncode(_user!.toJson()));
    } else {
      await prefs.remove('userData');
    }

    // Crisis
    final List<String> listJson = _registeredCrises
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await prefs.setStringList('registeredCrises', listJson);

    // Teléfono
    if (_emergencyPhone != null) {
      await prefs.setString('emergencyPhone', _emergencyPhone!);
    } else {
      await prefs.remove('emergencyPhone');
    }
  }

  // guarda o limpia el teléfono de emergencia; notifica cambios
  void setEmergencyPhone(String? phone) {
    final p = phone?.trim();
    _emergencyPhone = (p == null || p.isEmpty) ? null : p;
    _saveData(); // Guardar
    notifyListeners();
  }

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
    _registeredCrises.clear(); // Limpiar datos anteriores si cambia usuario
    _emergencyPhone = null;
    _saveData(); // Guardar
    notifyListeners();
  }

  // cierra sesión y limpia el historial local
  void logout() {
    _user = null;
    _registeredCrises.clear();
    _emergencyPhone = null;
    _saveData(); // Guardar limpieza
    notifyListeners();
  }

  // crea y agrega un nuevo registro de crisis
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
    _saveData(); // Guardar
    notifyListeners();
    return newCrisis;
  }

  // actualiza campos de una crisis existente
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
      _saveData(); // Guardar
      notifyListeners();
    }
  }
}