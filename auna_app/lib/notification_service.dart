// lib/notification_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// llave global que permite navegar desde una notificación
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  // patrón singleton para usar una sola instancia del servicio
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  // instancia principal del plugin de notificaciones
  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  // definición del canal android (nivel alto con sonido, luz y vibración)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'auna_crisis',
    'Crisis y alertas',
    description: 'notificaciones de crisis detectadas por el amuleto auna.',
    importance: Importance.max,
    playSound: true,
    enableLights: true,
    enableVibration: true,
    showBadge: true,
  );

  // inicializa permisos, canales y callbacks
  Future<void> init() async {
    // configuración inicial android e ios
    const androidInit = AndroidInitializationSettings('ic_launcher'); // usa mipmap/ic_launcher
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings =
        InitializationSettings(android: androidInit, iOS: darwinInit);

    // inicializa el plugin con los callbacks definidos
    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTapNotification,
      onDidReceiveBackgroundNotificationResponse: _onTapNotificationBackground,
    );

    if (Platform.isAndroid) {
      // crea el canal si no existe
      await _fln
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // para android 13 o superior: pedir permiso de notificaciones
      final notifGranted = await Permission.notification.isGranted;
      if (!notifGranted) {
        await Permission.notification.request();
      }
    }

    if (Platform.isIOS) {
      // solicita permisos en ios
      await _fln
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // muestra una notificación de crisis con un botón "editar"
  // [crisis] puede ser un objeto o un mapa con una clave 'id'
  Future<void> showCrisisNotification(dynamic crisis) async {
    final String crisisId = _extractCrisisId(crisis);

    // configuración android
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.recommendation, // heads-up
      // acción adicional que aparece en la notificación
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'EDITAR_CRISIS',
          'Editar',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    // configuración ios (permite mostrar alerta en foreground)
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'AUNA_CRISIS',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // muestra la notificación con id y payload únicos
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Crisis registrada',
      'Se registró correctamente. Toca para editar.',
      details,
      payload: crisisId, // se usa en el callback para navegar
    );
  }

  // función opcional de prueba rápida
  Future<void> showTest() async {
    await showCrisisNotification({'id': 'test'});
  }

  // ======== callbacks ========

  // se ejecuta cuando el usuario toca la notificación (app abierta o en segundo plano)
  void _onTapNotification(NotificationResponse r) {
    final payload = r.payload; // id de la crisis
    if (payload != null && payload.isNotEmpty) {
      _goToEdit(payload);
    }
  }

  // se ejecuta cuando se toca la notificación mientras la app está en background isolate (solo android)
  @pragma('vm:entry-point')
  static void _onTapNotificationBackground(NotificationResponse r) {
    final payload = r.payload;
    if (payload != null && payload.isNotEmpty) {
      // en background no se puede navegar directamente;
      // se delega a la instancia principal cuando la app vuelve al foreground
      _i._goToEdit(payload);
    }
  }

  // navega hacia la pantalla de edición de crisis
  void _goToEdit(String crisisId) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    // usa un microtask para asegurar que el contexto esté disponible
    Future.microtask(() {
      nav.pushNamed('/crisis/edit', arguments: {'crisisId': crisisId});
    });
  }

  // obtiene el id de la crisis desde un objeto o un mapa
  String _extractCrisisId(dynamic crisis) {
    try {
      if (crisis != null && crisis.id != null) return crisis.id.toString();
    } catch (_) {}
    try {
      if (crisis is Map && crisis['id'] != null) {
        return crisis['id'].toString();
      }
    } catch (_) {}
    // si no se encuentra id, genera uno temporal
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
