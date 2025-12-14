// lib/notification_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Llave global para navegación (asegúrate de que main.dart la use)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'auna_crisis',
    'Crisis y alertas',
    description: 'Notificaciones de crisis detectadas por el amuleto Auna.',
    importance: Importance.max,
    playSound: true,
    enableLights: true,
    enableVibration: true,
    showBadge: true,
  );

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // CORRECCIÓN AQUÍ: Cambiamos 'false' por 'true' para que iOS pida permiso
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,  // <--- IMPORTANTE
      requestBadgePermission: true,  // <--- IMPORTANTE
      requestSoundPermission: true,  // <--- IMPORTANTE
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentSound: true,
    );

    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTapNotification,
      onDidReceiveBackgroundNotificationResponse: _onTapNotificationBackground,
    );

    // Permisos adicionales para Android
    if (Platform.isAndroid) {
      await _fln
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  // --- MOSTRAR LA NOTIFICACIÓN ---
  Future<void> showCrisisNotification(Map<String, dynamic> crisisData) async {
    final String crisisId = crisisData['id'].toString();

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(''),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'EDITAR_CRISIS', 
          '✏️ Editar', 
          showsUserInterface: true, 
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,   // Forzar alerta visual
      presentSound: true,   // Forzar sonido
      presentBanner: true,  // Forzar banner
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _fln.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), 
      'Nuevo episodio detectado', 
      'Se ha registrado un nuevo episodio de dolor. Toca para completarlo.',
      details,
      payload: crisisId, 
    );
  }

  // ======== CALLBACKS ========

  void _onTapNotification(NotificationResponse r) {
    final payload = r.payload;
    if (payload != null && payload.isNotEmpty) {
      _goToEdit(payload);
    }
  }

  @pragma('vm:entry-point')
  static void _onTapNotificationBackground(NotificationResponse r) {
    final payload = r.payload;
    if (payload != null && payload.isNotEmpty) {
      _i._goToEdit(payload);
    }
  }

  void _goToEdit(String crisisId) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    
    // Navegamos a tu ruta '/crisis/edit' pasando el ID
    Future.microtask(() {
      nav.pushNamed('/crisis/edit', arguments: {'crisisId': crisisId});
    });
  }
}