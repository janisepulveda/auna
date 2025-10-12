// lib/user_provider.dart
import 'package:flutter/material.dart';

// una clase simple para guardar los datos del usuario.
class UserData {
  final String name;
  final String email;

  UserData({required this.name, required this.email});
}

// esta es la clase principal que manejará el estado.
// 'changenotifier' permite que "notifique" a los widgets cuando hay un cambio.
class UserProvider with ChangeNotifier {
  // guardamos los datos del usuario de forma privada.
  UserData? _user;

  // una forma pública de obtener los datos del usuario.
  UserData? get user => _user;

  // 1. añadimos un contador para las crisis, inicializado en 0.
  int _crisisCount = 0;

  // 2. creamos una forma pública de leer el contador.
  int get crisisCount => _crisisCount;

  // una función para "iniciar sesión".
  // recibe los datos, los guarda y notifica a todos los que estén escuchando.
  void login(String name, String email) {
    _user = UserData(name: name, email: email);
    notifyListeners();
  }

  // una función para "cerrar sesión".
  void logout() {
    _user = null;
    notifyListeners();
  }

  // 3. creamos una nueva función para cuando se registra una crisis.
  void registerCrisis() {
    _crisisCount++; // incrementa el contador.
    notifyListeners(); // notifica a la app que algo cambió para que la pantalla se redibuje.
  }
}