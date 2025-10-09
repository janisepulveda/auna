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

  // una función para "iniciar sesión".
  // recibe los datos, los guarda y notifica a todos los que estén escuchando.
  void login(String name, String email) {
    _user = UserData(name: name, email: email);
    // esta es la parte más importante: avisa a la app que los datos cambiaron.
    notifyListeners();
  }

  // una función para "cerrar sesión".
  void logout() {
    _user = null;
    notifyListeners();
  }
}