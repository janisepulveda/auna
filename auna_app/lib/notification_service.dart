// lib/notification_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Llave global para navegación
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
    // Asegúrate de tener el icono 'ic_launcher' en android/app/src/main/res/mipmap-*/
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
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

    if (Platform.isAndroid) {
      await _fln
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }

    if (Platform.isIOS) {
      await _fln
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // --- MOSTRAR LA NOTIFICACIÓN ---
  Future<void> showCrisisNotification(Map<String, dynamic> crisisData) async {
    // Como ahora siempre recibimos un mapa con ID, lo sacamos directo
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
      
      // BOTÓN DE ACCIÓN
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
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _fln.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), 
      'Nuevo episodio detectado', 
      'Se ha registrado un nuevo episodio de dolor. ¿Quieres editarlo?',
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
    
    Future.microtask(() {
      nav.pushNamed('/crisis/edit', arguments: {'crisisId': crisisId});
    });
  }
}