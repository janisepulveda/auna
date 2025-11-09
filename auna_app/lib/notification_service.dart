// lib/notification_service.dart
import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart'; // <-- 1. ELIMINADO (ya está en Material.dart)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'crisis_detail_screen.dart'; // Importa la pantalla de detalle

// 2. CORREGIDO: 'GlobalKey' no es const, debe ser 'final'
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Inicialización (sin cambios)
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'CRISIS_CATEGORY',
          actions: [
            DarwinNotificationAction.plain(
              'EDIT_ACTION',
              'Editar Detalles',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
          options: {DarwinNotificationCategoryOption.allowInCarPlay},
        )
      ],
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  // 3. Función para MOSTRAR la notificación (sin cambios)
  Future<void> showCrisisNotification(CrisisModel crisis) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'crisis_channel',
      'Detección de Crisis',
      channelDescription: 'Notificaciones cuando se detecta una crisis.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'EDIT_ACTION',
          'Editar Detalles',
          showsUserInterface: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'CRISIS_CATEGORY',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '¡Crisis Detectada!',
      'Hemos detectado una posible crisis. Toca "Editar" para añadir los detalles.',
      platformChannelSpecifics,
      payload: crisis.id,
    );
  }
}

// 4. Función de respuesta a la notificación (CORREGIDA para 'async gap')
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) async {
  final String? payload = response.payload;
  
  if (payload != null) {
    debugPrint('Abriendo crisis para editar, ID: $payload');
    
    // --- INICIO DE LA CORRECCIÓN ---
    if (navigatorKey.currentState != null) {
      // 1. Guarda el navigator y el context ANTES del 'await'
      final navigator = navigatorKey.currentState!;
      final context = navigator.context;

      // 2. Espera a que la app esté lista (salto asíncrono)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 3. Verifica si el context SIGUE VIVO después del 'await'
      if (!context.mounted) return; 

      final crisis = Provider.of<UserProvider>(context, listen: false).getCrisisById(payload);

      if (crisis != null) {
        // 4. Verifica de nuevo antes de navegar (doble seguridad)
        if (!context.mounted) return;
        navigator.push(
          MaterialPageRoute(
            builder: (context) => CrisisDetailScreen(crisisToEdit: crisis),
          ),
        );
      }
    }
    // --- FIN DE LA CORRECCIÓN ---
  }
}