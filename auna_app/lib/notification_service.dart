// lib/notification_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Llave global para navegar desde la acción de la notificación
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  // Canal Android (alto, con heads-up)
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

  /// Inicializa canales, permisos y callbacks
  Future<void> init() async {
    // ----- Android: create channel + initialize
    const androidInit = AndroidInitializationSettings('ic_launcher'); // usa mipmap/ic_launcher
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // categorías opcionales si luego agregas más acciones
    );

    final initSettings =
        const InitializationSettings(android: androidInit, iOS: darwinInit);

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTapNotification,
      onDidReceiveBackgroundNotificationResponse: _onTapNotificationBackground,
    );

    if (Platform.isAndroid) {
      // crear canal una sola vez
      await _fln
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Android 13+ (Tiramisu): pedir permiso de notificaciones
      final notifGranted = await Permission.notification.isGranted;
      if (!notifGranted) {
        await Permission.notification.request();
      }
    }

    if (Platform.isIOS) {
      // iOS: pedir permisos
      await _fln
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Muestra una notificación de crisis con botón "Editar"
  /// [crisis] puede ser tu objeto o un Map con 'id' (lo usamos como payload).
  Future<void> showCrisisNotification(dynamic crisis) async {
    final String crisisId = _extractCrisisId(crisis);

    // ANDROID
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.recommendation, // heads-up
      // Acción "Editar" (abre la app con payload)
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'EDITAR_CRISIS',
          'Editar',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    // iOS: forzar presentación también en foreground
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

    await _fln.show(
      // id único (puedes usar un hash si quieres)
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Crisis registrada',
      'Se registró correctamente. Toca para editar.',
      details,
      payload: crisisId, // <-- se usa en el callback para navegar
    );
  }

  /// (Opcional) test rápido
  Future<void> showTest() async {
    await showCrisisNotification({'id': 'test'});
  }

  // ========= Callbacks =========

  // Tap en la notificación (app en foreground/background)
  void _onTapNotification(NotificationResponse r) {
    final payload = r.payload; // nuestro crisisId
    // Si el usuario tocó la acción "Editar" o el cuerpo de la notificación
    if (payload != null && payload.isNotEmpty) {
      _goToEdit(payload);
    }
  }

  // Tap en background isolate (Android)
  @pragma('vm:entry-point')
  static void _onTapNotificationBackground(NotificationResponse r) {
    // En background solo podemos almacenar/reenviar; aquí lo delegamos a _i
    final payload = r.payload;
    if (payload != null && payload.isNotEmpty) {
      // No podemos navegar aquí directamente; la navegación real ocurrirá
      // cuando la app vuelva al foreground. Guardar estado global si se desea.
      // Para simplificar, intentaremos navegar si hay navigatorKey listo:
      _i._goToEdit(payload);
    }
  }

  void _goToEdit(String crisisId) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    // Si la app no tiene una ruta abierta aún, un pequeño delay ayuda
    Future.microtask(() {
      nav.pushNamed('/crisis/edit', arguments: {'crisisId': crisisId});
    });
  }

  String _extractCrisisId(dynamic crisis) {
    try {
      // Si es tu modelo y tiene "id"
      if (crisis != null && crisis.id != null) return crisis.id.toString();
    } catch (_) {}
    try {
      if (crisis is Map && crisis['id'] != null) {
        return crisis['id'].toString();
      }
    } catch (_) {}
    // fallback
    return DateTime.now().millisecondsSinceEpoch.toString();
    }
}
