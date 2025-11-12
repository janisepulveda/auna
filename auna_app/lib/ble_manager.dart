// lib/ble_manager.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'dart:math'; // opcional si se necesita para cálculos adicionales

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';
import 'user_provider.dart';

class BleManager extends ChangeNotifier {
  // ===== configuración general =====
  // nombre visible del dispositivo bluetooth a conectar
  final String deviceName = 'Auna';

  // identificadores únicos del servicio y característica definidos en el firmware del esp32
  final Uuid serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid charUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  // ===== estado público para la interfaz =====
  // instancia del plugin principal ble
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // texto visible del estado actual
  String connectionStateLabel = 'Desconectado';

  // id del dispositivo conectado
  String? connectedDeviceId;

  // getter para saber si el dispositivo está conectado
  bool get isConnected => connectionStateLabel == 'Conectado';

  // ===== variables internas =====
  // suscripciones a streams para escaneo, conexión y notificaciones
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  // parámetros para reconexión automática
  bool _keepConnected = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  String? _lastDeviceId;

  // bloqueo temporal para evitar múltiples registros de crisis consecutivos
  bool _crisisLock = false;
  DateTime _lastCrisis = DateTime.fromMillisecondsSinceEpoch(0);

  // referencia al provider del usuario para registrar crisis y acceder a datos globales
  UserProvider? userProvider;

  // ===== api pública =====
  // inicia el proceso de conexión al dispositivo
  Future<void> connect() async {
    _keepConnected = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    connectionStateLabel = 'Buscando...';
    connectedDeviceId = null;
    notifyListeners();

    // verifica permisos requeridos antes de iniciar el escaneo
    final ok = await _ensurePermissions();
    if (!ok) {
      connectionStateLabel = 'Permisos denegados';
      notifyListeners();
      return;
    }

    // si ya se conoce el id del último dispositivo, se conecta directamente
    if (_lastDeviceId != null) {
      _connectTo(_lastDeviceId!);
      return;
    }

    // inicia el escaneo de dispositivos con el servicio especificado
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

    // si después de 20 segundos no se encuentra el dispositivo, se reintenta
    Future.delayed(const Duration(seconds: 20), () {
      if (!found && connectionStateLabel == 'Buscando...') {
        _scanSub?.cancel();
        connectionStateLabel = 'No encontrado';
        notifyListeners();
        _scheduleReconnect();
      }
    });
  }

  // desconecta completamente el dispositivo y limpia los streams
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
    // limpia recursos cuando se destruye el objeto
    _keepConnected = false;
    _reconnectTimer?.cancel();
    _notifySub?.cancel();
    _connSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  // ===== permisos =====
  // verifica y solicita permisos de bluetooth y ubicación
  Future<bool> _ensurePermissions() async {
    try {
      if (Platform.isAndroid) {
        final status = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse, // requerido en android < 12
        ].request();

        final granted = (status[Permission.bluetoothScan]?.isGranted ?? false) &&
            (status[Permission.bluetoothConnect]?.isGranted ?? false) &&
            (status[Permission.locationWhenInUse]?.isGranted ?? true);

        return granted;
      } else if (Platform.isIOS) {
        // espera a que el estado del ble sea "ready"
        BleStatus current = await _ble.statusStream.first;
        if (current == BleStatus.ready) return true;
        final ready = await _ble.statusStream
            .timeout(const Duration(seconds: 6))
            .firstWhere((s) => s == BleStatus.ready, orElse: () => current);
        return ready == BleStatus.ready;
      } else {
        // otros sistemas: asume permiso concedido
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  // ===== conexión =====
  // intenta conectar con un dispositivo específico por id
  void _connectTo(String deviceId) {
    _lastDeviceId = deviceId;

    _connSub?.cancel();
    _connSub = _ble
        .connectToDevice(id: deviceId, connectionTimeout: const Duration(seconds: 20))
        .listen((u) {
      switch (u.connectionState) {
        case DeviceConnectionState.connected:
          // se estableció la conexión
          connectedDeviceId = deviceId;
          connectionStateLabel = 'Conectado';
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
          notifyListeners();
          _subscribeToNotifications(deviceId);
          break;
        case DeviceConnectionState.disconnected:
          // se perdió la conexión
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
      // si ocurre un error, se programa reconexión
      connectionStateLabel = 'Error conexión';
      notifyListeners();
      _scheduleReconnect();
    });
  }

  // ===== reconexión =====
  // programa un nuevo intento de conexión usando retroceso exponencial
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

  // devuelve segundos de espera entre intentos según la cantidad de fallos
  int _backoffSeconds(int attempt) {
    final table = [1, 2, 4, 8, 12, 15];
    return attempt < table.length ? table[attempt] : 15;
  }

  // ===== suscripción a notificaciones =====
  // escucha los datos enviados por el esp32 y ejecuta acciones según el contenido
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

      // si el mensaje es "crisis", se ejecuta la rutina correspondiente
      if (text == 'CRISIS') {
        _handleCrisis();
        return;
      }
      // si el mensaje es "emergencia", se ejecuta la rutina de emergencia
      if (text == 'EMERGENCIA') {
        _handleEmergency();
        return;
      }
      // otros posibles datos futuros pueden procesarse aquí
    }, onError: (_) {
      // los errores del stream no rompen la conexión principal
    });
  }

  // ===== manejo de crisis =====
  // registra una crisis si el dispositivo envía la palabra "crisis"
  void _handleCrisis() {
    final now = DateTime.now();

    // evita múltiples registros seguidos (cooldown de 8 segundos)
    if (now.difference(_lastCrisis).inSeconds < 8) return;
    _lastCrisis = now;

    if (_crisisLock) return;
    _crisisLock = true;

    // registra la crisis en el modelo del usuario y muestra notificación
    final up = userProvider;
    dynamic crisis;
    try {
      crisis = up?.registerCrisis(
        intensity: 0,
        duration: 0,
        notes: 'registrada por el amuleto (tap corto).',
        trigger: 'otro',
        symptoms: const [],
      );
    } catch (_) {}

    // muestra una notificación local
    NotificationService().showCrisisNotification(crisis);

    // libera el bloqueo después de 20 segundos
    Future.delayed(const Duration(seconds: 20), () {
      _crisisLock = false;
    });
  }

  // ===== manejo de emergencia =====
  // ejecuta acciones cuando el dispositivo envía "emergencia"
  Future<void> _handleEmergency() async {
    final up = userProvider;
    final String? phone = up?.emergencyPhone;

    if (phone == null || phone.trim().isEmpty) {
      // si no hay teléfono configurado, muestra una notificación genérica
      NotificationService().showCrisisNotification({
        'id': 'emergencia_sin_contacto'
      });
      return;
    }

    // en modo servicio no se pueden abrir sms directamente, así que se notifica al usuario
    NotificationService().showCrisisNotification({
      'id': 'emergencia_${DateTime.now().millisecondsSinceEpoch}'
    });

    // la acción real (abrir sms o llamada) se maneja cuando el usuario toca la notificación
  }
}
