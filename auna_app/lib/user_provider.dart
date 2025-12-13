// lib/user_provider.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

var uuid = const Uuid();

// --- MODELOS ---

class UserData {
  final String name;
  final String email;
  UserData({required this.name, required this.email});

  Map<String, dynamic> toJson() => {'name': name, 'email': email};
  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    name: json['name'],
    email: json['email'],
  );
}

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'intensity': intensity,
    'duration': duration,
    'notes': notes,
    'trigger': trigger,
    'symptoms': symptoms,
  };

  factory CrisisModel.fromJson(Map<String, dynamic> json) => CrisisModel(
    id: json['id'],
    date: DateTime.parse(json['date']),
    intensity: (json['intensity'] as num).toDouble(),
    duration: json['duration'],
    notes: json['notes'],
    trigger: json['trigger'],
    symptoms: List<String>.from(json['symptoms']),
  );
}

// --- PROVIDER ---

class UserProvider with ChangeNotifier {
  
  UserProvider() {
    loadData(); 
  }

  UserData? _user;
  UserData? get user => _user;

  List<CrisisModel> _registeredCrises = [];
  List<CrisisModel> get registeredCrises => _registeredCrises;

  // Contacto de emergencia
  String? _emergencyName;
  String? get emergencyName => _emergencyName;
  String? _emergencyPhone;
  String? get emergencyPhone => _emergencyPhone;

  // --- CARGAR DATOS ---
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final String? userJson = prefs.getString('userData');
    if (userJson != null) {
      _user = UserData.fromJson(jsonDecode(userJson));
    }

    final List<String> crisesJson = prefs.getStringList('registeredCrises') ?? [];
    _registeredCrises = crisesJson
        .map((str) => CrisisModel.fromJson(jsonDecode(str)))
        .toList();

    _emergencyPhone = prefs.getString('emergencyPhone');
    _emergencyName = prefs.getString('emergencyName');
    
    notifyListeners();
  }

  // --- GUARDAR DATOS ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_user != null) {
      await prefs.setString('userData', jsonEncode(_user!.toJson()));
    } else {
      await prefs.remove('userData');
    }

    final List<String> listJson = _registeredCrises
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await prefs.setStringList('registeredCrises', listJson);

    if (_emergencyPhone != null) {
      await prefs.setString('emergencyPhone', _emergencyPhone!);
    } else {
      await prefs.remove('emergencyPhone');
    }
    if (_emergencyName != null) {
      await prefs.setString('emergencyName', _emergencyName!);
    } else {
      await prefs.remove('emergencyName');
    }
  }

  void setEmergencyContact(String? name, String? phone) {
    final p = phone?.trim();
    final n = name?.trim();
    _emergencyPhone = (p == null || p.isEmpty) ? null : p;
    _emergencyName = (n == null || n.isEmpty) ? null : n;
    _saveData();
    notifyListeners();
  }

  CrisisModel? getCrisisById(String id) {
    try {
      return _registeredCrises.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // --- REGISTRO MANUAL ---
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
    _saveData();
    notifyListeners();
    return newCrisis;
  }

  // --- ACTUALIZAR (AL EDITAR) ---
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
      _saveData();
      notifyListeners();
    }
  }

  // =========================================================
  //        FUNCIONES PARA EL AMULETO (BLE)
  // =========================================================

  // 1. REGISTRO RÁPIDO (DATOS INCOMPLETOS)
  String registerQuickCrisis() {
    final now = DateTime.now();
    final newId = uuid.v4();

    final newCrisis = CrisisModel(
      id: newId,
      date: now,
      // INTENSIDAD -1 PARA INDICAR "FALTA COMPLETAR"
      intensity: -1.0, 
      duration: 0,     
      notes: "Registro automático desde Amuleto",
      trigger: "Desconocido",
      symptoms: [],
    );

    _registeredCrises.add(newCrisis);
    _saveData();
    notifyListeners();
    
    debugPrint("✅ Crisis parcial guardada (Solo Hora). ID: $newId");
    return newId; // Retornamos ID para la notificación
  }

  // 2. PROTOCOLO DE EMERGENCIA
  Future<void> triggerEmergencyProtocol() async {
    if (_emergencyPhone == null) return;

    const mensaje = "Hola, estoy pasando por un episodio de dolor intenso. Por favor contáctame.";
    
    final uri = Uri(
      scheme: 'sms',
      path: _emergencyPhone,
      queryParameters: {'body': mensaje},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        final uriString = 'sms:$_emergencyPhone?body=${Uri.encodeComponent(mensaje)}';
        await launchUrl(Uri.parse(uriString));
      }
    } catch (e) {
      debugPrint('Error SMS: $e');
    }
  }

  // --- LOGIN/LOGOUT ---
  void login(String name, String email) {
    _user = UserData(name: name, email: email);
    _saveData();
    notifyListeners();
  }
  void logout() {
    _user = null;
    _registeredCrises.clear();
    _saveData();
    notifyListeners();
  }
}