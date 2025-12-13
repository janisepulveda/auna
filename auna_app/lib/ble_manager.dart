import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';
import 'user_provider.dart';

class BleManager extends ChangeNotifier {
  // CONFIGURACIÓN (Debe coincidir con tu Arduino ESP32)
  final String deviceName = 'Auna';
  final Uuid serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid charUuid    = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  // ESTADO
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  String connectionStateLabel = 'Desconectado';
  String? connectedDeviceId;
  bool get isConnected => connectionStateLabel == 'Conectado';

  // CONTROL INTERNO
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  bool _keepConnected = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  String? _lastDeviceId;

  // Evitar rebote de señales (doble registro)
  bool _crisisLock = false;
  DateTime _lastCrisis = DateTime.fromMillisecondsSinceEpoch(0);

  // REFERENCIA AL USER PROVIDER (Se inyecta desde main.dart)
  UserProvider? userProvider;

  // =========================================================
  //                 CONEXIÓN Y ESCANEO
  // =========================================================

  Future<void> connect() async {
    _keepConnected = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _lastDeviceId = null; 

    connectionStateLabel = 'Buscando...';
    notifyListeners();

    if (!await _ensurePermissions()) {
      connectionStateLabel = 'Sin permisos';
      notifyListeners();
      return;
    }

    _scanSub?.cancel();
    bool found = false;

    debugPrint("🔍 Iniciando escaneo de '$deviceName'...");

    _scanSub = _ble.scanForDevices(withServices: []).listen((d) {
      if (d.name.trim() == deviceName) {
        debugPrint("✅ AUNA ENCONTRADO! ID: ${d.id}");
        found = true;
        _scanSub?.cancel();
        connectionStateLabel = 'Conectando...';
        notifyListeners();
        _connectTo(d.id);
      }
    }, onError: (e) {
      debugPrint("❌ Error escaneo: $e");
      _scheduleReconnect();
    });

    // Timeout de 15s si no encuentra nada
    Future.delayed(const Duration(seconds: 15), () {
      if (!found && connectionStateLabel == 'Buscando...') {
        _scanSub?.cancel();
        connectionStateLabel = 'No encontrado';
        notifyListeners();
      }
    });
  }

  void _connectTo(String deviceId) {
    _lastDeviceId = deviceId;
    _connSub?.cancel();
    
    _connSub = _ble
        .connectToDevice(id: deviceId, connectionTimeout: const Duration(seconds: 15))
        .listen((u) {
      
      switch (u.connectionState) {
        case DeviceConnectionState.connected:
          debugPrint("🔗 Conectado a $deviceId");
          connectedDeviceId = deviceId;
          connectionStateLabel = 'Conectado';
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
          notifyListeners();
          
          // Suscribirse a los datos inmediatamente
          _subscribeToNotifications(deviceId);
          break;
          
        case DeviceConnectionState.disconnected:
          debugPrint("🔌 Desconectado");
          if (connectedDeviceId == deviceId) {
            _notifySub?.cancel();
            connectedDeviceId = null;
            connectionStateLabel = 'Desconectado';
            notifyListeners();
          }
          _scheduleReconnect();
          break;
        default:
          // Manejar estados intermedios si quieres
          break;
      }
    }, onError: (e) {
      debugPrint("❌ Error conexión: $e");
      _scheduleReconnect();
    });
  }

  void disconnect() async {
    _keepConnected = false;
    _reconnectTimer?.cancel();
    await _notifySub?.cancel();
    await _connSub?.cancel();
    await _scanSub?.cancel();
    
    connectionStateLabel = 'Desconectado';
    connectedDeviceId = null;
    notifyListeners();
  }

  // =========================================================
  //              LÓGICA DE DATOS (CRISIS/EMERGENCIA)
  // =========================================================

  void _subscribeToNotifications(String deviceId) {
    final ch = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: charUuid,
      deviceId: deviceId,
    );

    _notifySub?.cancel();
    _notifySub = _ble.subscribeToCharacteristic(ch).listen((data) {
      String text = '';
      try {
        text = utf8.decode(data).trim(); // Decodificar bytes a texto
        debugPrint("📩 Dato recibido: $text");
      } catch (_) {}

      if (text == 'CRISIS') {
        _handleCrisis();
      } else if (text == 'EMERGENCIA') {
        _handleEmergency();
      }
    }, onError: (e) {
      debugPrint("Error recibiendo datos: $e");
    });
  }

  // MANEJO DE CRISIS (Toque corto)
  void _handleCrisis() {
    final now = DateTime.now();
    // Cooldown de 5 segundos para no spamear
    if (now.difference(_lastCrisis).inSeconds < 5) return;
    _lastCrisis = now;

    if (_crisisLock) return;
    _crisisLock = true;

    debugPrint(">>> 🚨 REGISTRANDO CRISIS AUTOMÁTICA <<<");

    final up = userProvider;
    
    if (up != null) {
       // PASO 1: Guardar en BD (Silencioso)
       // Esto asegura que la fecha quede registrada AHORA MISMO.
       String newCrisisId = up.registerQuickCrisis(); 
       
       // PASO 2: Mostrar Notificación con Botón "Editar"
       // Le pasamos el ID que acabamos de crear
       NotificationService().showCrisisNotification({
         'id': newCrisisId,
       });
    }

    // Liberar bloqueo después de 5s
    Future.delayed(const Duration(seconds: 5), () {
      _crisisLock = false;
    });
  }

  // MANEJO DE EMERGENCIA (Toque largo > 3s)
  Future<void> _handleEmergency() async {
    debugPrint(">>> 🆘 ALERTA DE EMERGENCIA DETECTADA <<<");
    
    final up = userProvider;
    if (up != null) {
      await up.triggerEmergencyProtocol();
    }
  }

  // =========================================================
  //                  UTILIDADES INTERNAS
  // =========================================================

  Future<bool> _ensurePermissions() async {
    if (Platform.isAndroid) {
      final status = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final scanOk = status[Permission.bluetoothScan]?.isGranted ?? false;
      final connectOk = status[Permission.bluetoothConnect]?.isGranted ?? false;
      final locOk = status[Permission.locationWhenInUse]?.isGranted ?? true; 

      // Compatibilidad con Android < 12 (donde scan/connect no existen)
      return (scanOk && connectOk) || locOk; 
    }
    return true; // iOS
  }

  void _scheduleReconnect() {
    if (!_keepConnected) return;
    _reconnectTimer?.cancel();

    final secs = _backoffSeconds(_reconnectAttempts++);
    if (connectionStateLabel != 'Conectado') {
      connectionStateLabel = 'Reintentando en ${secs}s...';
      notifyListeners();
    }

    _reconnectTimer = Timer(Duration(seconds: secs), () {
      if (!_keepConnected) return;
      if (_lastDeviceId != null) _connectTo(_lastDeviceId!);
      else connect();
    });
  }

  int _backoffSeconds(int attempt) {
    final table = [1, 2, 4, 8, 12, 15];
    return attempt < table.length ? table[attempt] : 15;
  }
}