// lib/ble_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
//import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';
import 'user_provider.dart';

class BleManager extends ChangeNotifier {
  // ===== Config =====
  final String deviceName = 'Auna';
  final Uuid serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid charUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  // ===== Estado público para la UI =====
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  String connectionStateLabel = 'Desconectado';
  String? connectedDeviceId;
  bool get isConnected => connectionStateLabel == 'Conectado';

  // ===== Interno =====
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  // Auto-reconexión
  bool _keepConnected = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  String? _lastDeviceId;

  // Anti-spam crisis
  bool _crisisLock = false;
  DateTime _lastCrisis = DateTime.fromMillisecondsSinceEpoch(0);

  // Inyección del proveedor de usuario (para registrar crisis)
  UserProvider? userProvider;

  // ===== API =====
  Future<void> connect() async {
    _keepConnected = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    connectionStateLabel = 'Buscando...';
    connectedDeviceId = null;
    notifyListeners();

    final ok = await _ensurePermissions();
    if (!ok) {
      connectionStateLabel = 'Permisos denegados';
      notifyListeners();
      return;
    }

    // Conecta directo si ya sabemos el id
    if (_lastDeviceId != null) {
      _connectTo(_lastDeviceId!);
      return;
    }

    bool found = false;
    _scanSub?.cancel();
    _scanSub = _ble.scanForDevices(withServices: [serviceUuid]).listen((d) {
      if (d.name == deviceName) {
        found = true;
        _scanSub?.cancel();
        connectionStateLabel = 'Conectando...';
        notifyListeners();
        _connectTo(d.id);
      }
    }, onError: (_) {
      connectionStateLabel = 'Error escaneo';
      notifyListeners();
      _scheduleReconnect();
    });

    Future.delayed(const Duration(seconds: 20), () {
      if (!found && connectionStateLabel == 'Buscando...') {
        _scanSub?.cancel();
        connectionStateLabel = 'No encontrado';
        notifyListeners();
        _scheduleReconnect();
      }
    });
  }

  Future<void> disconnect() async {
    _keepConnected = false;
    _reconnectTimer?.cancel();

    await _notifySub?.cancel();
    await _connSub?.cancel();
    await _scanSub?.cancel();

    _notifySub = null;
    _connSub = null;
    _scanSub = null;

    connectionStateLabel = 'Desconectado';
    connectedDeviceId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _keepConnected = false;
    _reconnectTimer?.cancel();
    _notifySub?.cancel();
    _connSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  // ===== Internals =====
  Future<bool> _ensurePermissions() async {
    try {
      if (Platform.isAndroid) {
        final status = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse, // en < Android 12
        ].request();

        final granted = (status[Permission.bluetoothScan]?.isGranted ?? false) &&
            (status[Permission.bluetoothConnect]?.isGranted ?? false) &&
            (status[Permission.locationWhenInUse]?.isGranted ?? true);

        return granted;
      } else if (Platform.isIOS) {
        // Espera a que CoreBluetooth esté listo
        BleStatus current = await _ble.statusStream.first;
        if (current == BleStatus.ready) return true;
        final ready = await _ble.statusStream
            .timeout(const Duration(seconds: 6))
            .firstWhere((s) => s == BleStatus.ready, orElse: () => current);
        return ready == BleStatus.ready;
      } else {
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  void _connectTo(String deviceId) {
    _lastDeviceId = deviceId;

    _connSub?.cancel();
    _connSub = _ble
        .connectToDevice(id: deviceId, connectionTimeout: const Duration(seconds: 20))
        .listen((u) {
      switch (u.connectionState) {
        case DeviceConnectionState.connected:
          connectedDeviceId = deviceId;
          connectionStateLabel = 'Conectado';
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
          notifyListeners();
          _subscribeToNotifications(deviceId);
          break;
        case DeviceConnectionState.disconnected:
          if (connectedDeviceId == deviceId) {
            _notifySub?.cancel();
            connectedDeviceId = null;
            connectionStateLabel = 'Desconectado';
            notifyListeners();
          }
          _scheduleReconnect();
          break;
        case DeviceConnectionState.connecting:
          connectionStateLabel = 'Conectando...';
          notifyListeners();
          break;
        case DeviceConnectionState.disconnecting:
          connectionStateLabel = 'Desconectando...';
          notifyListeners();
          break;
      }
    }, onError: (_) {
      connectionStateLabel = 'Error conexión';
      notifyListeners();
      _scheduleReconnect();
    });
  }

  void _scheduleReconnect() {
    if (!_keepConnected) return;
    _reconnectTimer?.cancel();

    final secs = _backoffSeconds(_reconnectAttempts);
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: secs), () {
      if (!_keepConnected) return;
      if (_lastDeviceId != null) {
        _connectTo(_lastDeviceId!);
      } else {
        connect();
      }
    });

    if (connectionStateLabel != 'Conectado') {
      connectionStateLabel = 'Reconectando en ${secs}s...';
      notifyListeners();
    }
  }

  int _backoffSeconds(int attempt) {
    final table = [1, 2, 4, 8, 12, 15];
    return attempt < table.length ? table[attempt] : 15;
  }

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
        text = utf8.decode(data).trim();
      } catch (_) {}

      if (text == 'CRISIS') {
        _handleCrisis();
        return;
      }
      if (text == 'EMERGENCIA') {
        _handleEmergency();
        return;
      }
      // Si en el futuro mandas números continuos, puedes procesarlos acá.
    }, onError: (_) {
      // Mantén estado; reconexión la maneja el stream de connection.
    });
  }

  void _handleCrisis() {
    // cooldown de 8s
    final now = DateTime.now();
    if (now.difference(_lastCrisis).inSeconds < 8) return;
    _lastCrisis = now;

    if (_crisisLock) return;
    _crisisLock = true;

    // Registrar crisis en tu modelo + notificar
    final up = userProvider;
    dynamic crisis;
    try {
      crisis = up?.registerCrisis(
        intensity: 0,
        duration: 0,
        notes: 'Registrada por el amuleto (tap corto).',
        trigger: 'Otro',
        symptoms: const [],
      );
    } catch (_) {}

    NotificationService().showCrisisNotification(crisis);

    Future.delayed(const Duration(seconds: 20), () {
      _crisisLock = false;
    });
  }

  Future<void> _handleEmergency() async {
    final up = userProvider;
    final String? phone = up?.emergencyPhone;

    if (phone == null || phone.trim().isEmpty) {
      // sin contexto de UI; dejamos la notificación local como feedback
      NotificationService().showCrisisNotification({
        'id': 'emergencia_sin_contacto'
      });
      return;
    }

    // No abrimos SMS aquí porque estamos en servicio (sin context).
    // Opcional: enviar una notificación que, al tocarla, abra el SMS.
    NotificationService().showCrisisNotification({
      'id': 'emergencia_${DateTime.now().millisecondsSinceEpoch}'
    });
    // La navegación/acción real la puedes manejar en la app al abrir.
  }
}
