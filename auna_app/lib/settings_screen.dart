// lib/settings_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_provider.dart';
import 'notification_service.dart';

// ===== Modo de lectura BLE =====
// false = usa SOLO eventos "CRISIS"/"EMERGENCIA" (tu firmware actual)
// true  = espera también valores numéricos de FSR (aparece calibración/nivel)
const bool kUseContinuousFSR = false;

// ===== Paleta
const _navy = Color(0xFF38455C);
const _bg = Color(0xFFF0F7FA);

// ===== Utilidad de escala
double _sx(BuildContext c, [double v = 1]) {
  final w = MediaQuery.of(c).size.width;
  final s = (w / 390).clamp(.75, 0.95);
  return v * s;
}

// ===== Glass helpers
BoxDecoration _glassContainer({required BuildContext context}) => BoxDecoration(
      borderRadius: BorderRadius.circular(_sx(context, 16)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.15),
        ],
      ),
      border: Border.all(color: Colors.white.withOpacity(0.48), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFAABEDC).withOpacity(0.12),
          blurRadius: _sx(context, 10),
          offset: Offset(0, _sx(context, 5)),
        ),
      ],
    );

class _GlassSurface extends StatelessWidget {
  final Widget child;
  const _GlassSurface({required this.child});

  static EdgeInsets _defaultPad(BuildContext c) => EdgeInsets.all(_sx(c, 10));

  @override
  Widget build(BuildContext context) {
    final r = _sx(context, 16);
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: _sx(context, 10),
          sigmaY: _sx(context, 10),
        ),
        child: Container(
          decoration: _glassContainer(context: context),
          padding: _defaultPad(context),
          child: child,
        ),
      ),
    );
  }
}

// ===== Card de acción
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = _sx(context, 32);
    final tileSide = _sx(context, 48);
    final gap = _sx(context, 10);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _GlassSurface(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_sx(context, 14)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: _sx(context, 8),
                  sigmaY: _sx(context, 8),
                ),
                child: Container(
                  width: tileSide,
                  height: tileSide,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_sx(context, 14)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.6)),
                  ),
                  child: Icon(icon, color: _navy, size: iconSize),
                ),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _navy,
                      fontSize: _sx(context, 16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: _sx(context, 2)),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _navy.withOpacity(0.72),
                      fontSize: _sx(context, 12.5),
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _sx(context, 6)),
            Icon(Icons.chevron_right, color: _navy.withOpacity(0.7), size: _sx(context, 22)),
          ],
        ),
      ),
    );
  }
}

// ===================== SETTINGS SCREEN =====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ------- BLE
  final _ble = FlutterReactiveBle();
  String _estadoConexion = 'Desconectado';
  final String _nombreEsp32 = 'Auna';

  final Uuid _uuidServicio = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid _uuidCaracteristica = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  StreamSubscription<DiscoveredDevice>? _suscripcionEscaneo;
  StreamSubscription<ConnectionStateUpdate>? _suscripcionConexion;
  StreamSubscription<List<int>>? _suscripcionDatos;
  String? _connectedDeviceId;

  // ------- Calibración / mapeo a nivel 0–10 (se usa sólo si kUseContinuousFSR = true)
  int _nivelDolor = 0;
  bool _actividadDetectada = false; // equivalente a "hay presión" si nivel > 0
  bool _estaCalibrando = false;
  int _valorMaximoDolor = 0;
  List<int> _valoresCalibracion = [];

  // anti-spam para notificación automática de "CRISIS"
  bool _crisisNotificada = false;
  DateTime _ultimoCrisis = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _cargarValorMaximo();
  }

  // ====== Persistencia de calibración
  Future<void> _cargarValorMaximo() async {
    if (!kUseContinuousFSR) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _valorMaximoDolor = prefs.getInt('valorMaximoDolor') ?? 0;
    });
  }

  Future<void> _guardarValorMaximo(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('valorMaximoDolor', v);
  }

  // ====== Ciclo de vida
  @override
  void dispose() {
    _suscripcionEscaneo?.cancel();
    _suscripcionConexion?.cancel();
    _suscripcionDatos?.cancel();
    super.dispose();
  }

  // ====== Permisos (Android + chequeo fiable en iOS con BleStatus)
  Future<bool> _solicitarPermisos() async {
    try {
      if (Platform.isAndroid) {
        final status = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse, // solo relevante en < Android 12
        ].request();

        final granted = (status[Permission.bluetoothScan]?.isGranted ?? false) &&
            (status[Permission.bluetoothConnect]?.isGranted ?? false) &&
            (status[Permission.locationWhenInUse]?.isGranted ?? true);

        if (!granted && mounted) {
          setState(() => _estadoConexion = 'Permisos de Bluetooth no concedidos');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activa Bluetooth (y Ubicación en Android <12).')),
          );
        }
        return granted;
      } else if (Platform.isIOS) {
        // En iOS confiamos en el estado de CoreBluetooth via flutter_reactive_ble
        return await _esperarBleListoIOS();
      } else {
        return true;
      }
    } catch (e) {
      if (mounted) setState(() => _estadoConexion = 'Error al solicitar permisos');
      return false;
    }
  }

  Future<bool> _esperarBleListoIOS() async {
    try {
      // Estado actual
      BleStatus current = await _ble.statusStream.first;
      if (current == BleStatus.ready) return true;

      // Espera hasta 6 s a que pase a READY (si el usuario enciende BT al vuelo)
      final ready = await _ble.statusStream
          .timeout(const Duration(seconds: 6))
          .firstWhere((s) => s == BleStatus.ready, orElse: () => current);

      if (ready == BleStatus.ready) return true;

      if (!mounted) return false;
      switch (ready) {
        case BleStatus.poweredOff:
          setState(() => _estadoConexion = 'Bluetooth apagado');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enciende Bluetooth en Ajustes o el Centro de Control.')),
          );
          break;
        case BleStatus.unauthorized:
          setState(() => _estadoConexion = 'Acceso a Bluetooth denegado');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ve a Ajustes > Privacidad > Bluetooth y habilita “Auna”.'),
            ),
          );
          break;
        case BleStatus.unsupported:
          setState(() => _estadoConexion = 'Bluetooth no soportado en este dispositivo');
          break;
        case BleStatus.locationServicesDisabled:
          setState(() => _estadoConexion = 'Servicios de ubicación deshabilitados');
          break;
        default:
          setState(() => _estadoConexion = 'Bluetooth no disponible');
          break;
      }
      return false;
    } catch (_) {
      if (mounted) setState(() => _estadoConexion = 'Bluetooth no disponible');
      return false;
    }
  }

  // ====== Conexión
  void _iniciarConexion() async {
    await _suscripcionEscaneo?.cancel();
    await _suscripcionConexion?.cancel();
    await _suscripcionDatos?.cancel();
    _suscripcionEscaneo = null;
    _suscripcionConexion = null;
    _suscripcionDatos = null;

    if (!mounted) return;
    setState(() {
      _estadoConexion = 'Buscando...';
      _connectedDeviceId = null;
    });

    final ok = await _solicitarPermisos();
    if (!ok) {
      if (mounted && _estadoConexion == 'Buscando...') {
        // Si permisos fallaron, deja el estado acorde (ya lo setea _solicitarPermisos).
        setState(() => _estadoConexion = 'Permisos denegados');
      }
      return;
    }

    var found = false;
    _suscripcionEscaneo = _ble.scanForDevices(withServices: [_uuidServicio]).listen((device) {
      if (device.name == _nombreEsp32) {
        found = true;
        _suscripcionEscaneo?.cancel();
        if (mounted) setState(() => _estadoConexion = 'Conectando...');
        _conectarDispositivo(device.id);
      }
    }, onError: (_) {
      if (mounted) setState(() => _estadoConexion = 'Error escaneo');
    });

    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && !found && _estadoConexion == 'Buscando...') {
        _suscripcionEscaneo?.cancel();
        setState(() => _estadoConexion = 'No encontrado');
      }
    });
  }

  void _conectarDispositivo(String deviceId) {
    _suscripcionConexion?.cancel();
    _suscripcionConexion = _ble
        .connectToDevice(id: deviceId, connectionTimeout: const Duration(seconds: 20))
        .listen((update) {
      if (!mounted) return;
      switch (update.connectionState) {
        case DeviceConnectionState.connected:
          _connectedDeviceId = deviceId;
          _estadoConexion = 'Conectado';
          setState(() {});
          _leerDatos(deviceId);
          break;
        case DeviceConnectionState.disconnected:
          if (_connectedDeviceId == deviceId) {
            _suscripcionDatos?.cancel();
            _connectedDeviceId = null;
            _estadoConexion = 'Desconectado';
            _nivelDolor = 0;
            _actividadDetectada = false;
            setState(() {});
          }
          break;
        case DeviceConnectionState.connecting:
          _estadoConexion = 'Conectando...';
          setState(() {});
          break;
        case DeviceConnectionState.disconnecting:
          _estadoConexion = 'Desconectando...';
          setState(() {});
          break;
      }
    }, onError: (_) {
      if (mounted) setState(() => _estadoConexion = 'Error conexión');
    });
  }

  // ====== Lectura BLE (tokens CRISIS/EMERGENCIA + opcional FSR continuo)
  void _leerDatos(String deviceId) {
    final ch = QualifiedCharacteristic(
      serviceId: _uuidServicio,
      characteristicId: _uuidCaracteristica,
      deviceId: deviceId,
    );
    _suscripcionDatos?.cancel();
    _suscripcionDatos = _ble.subscribeToCharacteristic(ch).listen((data) {
      if (!mounted) return;

      String asText = '';
      try {
        asText = utf8.decode(data).trim();
      } catch (_) {
        // ignoramos payload no textual
      }

      // 1) Modo EVENTOS
      if (asText == 'CRISIS') {
        _onCrisisEvent();
        return;
      }
      if (asText == 'EMERGENCIA') {
        _onEmergencyEvent();
        return;
      }

      // 2) Modo FSR CONTINUO (solo si activas el flag)
      if (!kUseContinuousFSR) return;

      int? valorCrudo;
      if (asText.isNotEmpty) {
        valorCrudo = int.tryParse(asText);
      }
      valorCrudo ??= (data.isNotEmpty ? data.first : null);
      if (valorCrudo == null) return;

      if (_estaCalibrando) {
        _valoresCalibracion.add(valorCrudo);
        setState(() {}); // actualiza contador en UI
      } else {
        _calcularNivelDolor(valorCrudo);
      }
    }, onError: (_) {
      if (mounted) setState(() => _estadoConexion = 'Error lectura');
    });
  }

  // ====== Calibración (sólo activa si kUseContinuousFSR = true)
  void _iniciarCalibracion() {
    setState(() {
      _estaCalibrando = true;
      _valoresCalibracion = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calibración: presiona el amuleto con tu fuerza máxima.')),
    );
  }

  void _finalizarCalibracion() {
    if (_valoresCalibracion.isEmpty) {
      setState(() {
        _estaCalibrando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibración cancelada: sin lecturas.')),
      );
      return;
    }
    final presionMaxima = _valoresCalibracion.reduce(max);
    _valorMaximoDolor = presionMaxima;
    _guardarValorMaximo(_valorMaximoDolor);
    setState(() {
      _estaCalibrando = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calibración lista. Máximo registrado: $_valorMaximoDolor')),
    );
  }

  void _reiniciarCalibracion() {
    _valorMaximoDolor = 0;
    _guardarValorMaximo(0);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calibración reiniciada.')),
    );
  }

  // ====== Mapeo a nivel 0–10
  void _calcularNivelDolor(int valorCrudo) {
    if (_valorMaximoDolor == 0) {
      setState(() {
        _nivelDolor = 0;
        _actividadDetectada = false;
      });
      return;
    }
    int nivel = (valorCrudo * 10) ~/ _valorMaximoDolor;
    nivel = max(0, min(10, nivel));
    setState(() {
      _nivelDolor = nivel;
      _actividadDetectada = nivel > 0;
    });
  }

  // ====== Eventos
  void _onCrisisEvent() {
    // cooldown de 8s para evitar múltiples taps en cadena
    final now = DateTime.now();
    if (now.difference(_ultimoCrisis).inSeconds < 8) return;
    _ultimoCrisis = now;

    if (_crisisNotificada) return;
    setState(() => _crisisNotificada = true);

    final up = Provider.of<UserProvider>(context, listen: false);
    final crisis = up.registerCrisis(
      intensity: 0,
      duration: 0,
      notes: 'Registrada por el amuleto (tap corto).',
      trigger: 'Otro',
      symptoms: const [],
    );

    NotificationService().showCrisisNotification(crisis);

    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) setState(() => _crisisNotificada = false);
    });
  }

  Future<void> _onEmergencyEvent() async {
    final up = Provider.of<UserProvider>(context, listen: false);
    final String? phone = up.emergencyPhone; // e.g. "+569..."
    final String nombre = up.user?.name ?? 'Usuario Auna';

    if (phone == null || phone.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configura un contacto de emergencia en la app.')),
      );
      return;
    }

    final texto =
        'ALERTA AUNA: $nombre solicitó ayuda. Se detectó una crisis (presión larga en el amuleto).';

    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{'body': texto},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abriendo SMS para enviar alerta…')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el SMS en este dispositivo.')),
      );
    }
  }

  void _desconectar() async {
    await _suscripcionDatos?.cancel();
    await _suscripcionConexion?.cancel();
    _suscripcionDatos = null;
    _suscripcionConexion = null;
    if (mounted) {
      setState(() {
        _estadoConexion = 'Desconectado';
        _connectedDeviceId = null;
        _nivelDolor = 0;
        _actividadDetectada = false;
      });
    }
  }

  // ------- Helpers para PDF -------
  PdfColor get _pdfNavy => const PdfColor.fromInt(0xFF38455C);
  PdfColor get _pdfIce => const PdfColor.fromInt(0xFFE6F1F5);
  PdfColor get _pdfLine => const PdfColor.fromInt(0xFFB7C7D1);
  PdfColor get _pdfGrey => const PdfColor.fromInt(0xFF6B7A88);

  Map<String, int> countSymptoms(Iterable<String> xs) {
    final m = <String, int>{};
    for (final raw in xs) {
      final k = raw.trim();
      if (k.isEmpty) continue;
      m.update(k, (v) => v + 1, ifAbsent: () => 1);
    }
    return m;
  }

  Future<void> _pickAndExportPdf() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Exportar PDF'),
              subtitle: Text('Elige el período'),
            ),
            ListTile(
              leading: const Icon(Icons.all_inbox),
              title: const Text('Todo el historial'),
              onTap: () => Navigator.of(ctx).pop('all'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_month),
              title: const Text('Mes actual'),
              onTap: () => Navigator.of(ctx).pop('month'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Últimos 30 días'),
              onTap: () => Navigator.of(ctx).pop('30'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Elegir rango…'),
              onTap: () => Navigator.of(ctx).pop('range'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    DateTime? from;
    DateTime? to;
    if (choice == 'month') {
      final now = DateTime.now();
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month + 1, 1);
    } else if (choice == '30') {
      to = DateTime.now();
      from = to.subtract(const Duration(days: 30));
    } else if (choice == 'range') {
      if (!mounted) return;
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 5),
        initialDateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        ),
      );
      if (picked == null) return;
      from = picked.start;
      to = picked.end.add(const Duration(days: 1));
    }
    await _exportHistoryToPdf(from: from, to: to);
  }

  Future<void> _exportHistoryToPdf({DateTime? from, DateTime? to}) async {
    final pdf = pw.Document();
    if (!mounted) return;
    try {
      await initializeDateFormatting('es_CL', null);
      Intl.defaultLocale ??= 'es_CL';
    } catch (_) {}
    if (!mounted) return;

    final up = Provider.of<UserProvider>(context, listen: false);
    final all = up.registeredCrises.toList();
    final userName = up.user?.name ?? 'Usuario Auna';
    final start = from ?? DateTime.fromMillisecondsSinceEpoch(0);
    final end = to ?? DateTime.now();

    final crises = all.where((c) => c.date.isAfter(start) && c.date.isBefore(end)).toList();
    if (crises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay crisis en el período seleccionado.')),
      );
      return;
    }
    crises.sort((a, b) => a.date.compareTo(b.date));
    final df = DateFormat.yMMMMd('es_CL');
    final tf = DateFormat.Hm('es_CL');

    final totalIntensity = crises.fold<double>(0, (a, c) => a + c.intensity.toDouble());
    final avgIntensity = totalIntensity / crises.length;

    final durations =
        crises.map((c) => c.duration).whereType<int>().where((d) => d > 0).toList();
    final totalDuration = durations.isEmpty ? 0 : durations.reduce((a, b) => a + b);
    final double? avgDuration = durations.isEmpty ? null : totalDuration / durations.length;

    int leves = 0, moderados = 0, severos = 0;
    for (final c in crises) {
      final v = c.intensity.toInt();
      if (v <= 3) {
        leves++;
      } else if (v <= 7) {
        moderados++;
      } else {
        severos++;
      }
    }

    final symptomsCounts = countSymptoms(crises.expand((c) => c.symptoms));
    String symptomsSummary(Map<String, int> map, {int take = 6}) {
      if (map.isEmpty) return '-';
      final ord = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return ord.take(take).map((e) => '• ${e.key}: ${e.value}').join('\n');
    }

    final pdfNavy = _pdfNavy, pdfIce = _pdfIce, pdfLine = _pdfLine, pdfGrey = _pdfGrey;

    pw.Widget headCell(String t) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
          color: pdfIce,
          child: pw.Text(
            t,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: pdfNavy,
            ),
          ),
        );

    pw.Widget cell(String t,
            {pw.Alignment align = pw.Alignment.topLeft, double fs = 9.8}) =>
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4.5, horizontal: 6),
          alignment: align,
          child: pw.Text(t, style: pw.TextStyle(fontSize: fs), softWrap: true),
        );

    final summaryTable = pw.Table(
      border: pw.TableBorder.all(color: pdfLine, width: .6),
      columnWidths: const {0: pw.FixedColumnWidth(175), 1: pw.FlexColumnWidth(1)},
      children: [
        pw.TableRow(children: [headCell('Indicador'), headCell('Valor')]),
        pw.TableRow(children: [cell('Total de crisis'), cell('${crises.length}', align: pw.Alignment.center)]),
        pw.TableRow(children: [cell('Intensidad promedio'), cell(avgIntensity.toStringAsFixed(1), align: pw.Alignment.center)]),
        pw.TableRow(children: [cell('Distribución (Leves / Moderadas / Severas)'), cell('$leves / $moderados / $severos', align: pw.Alignment.center)]),
        pw.TableRow(children: [cell('Duración promedio (seg)'), cell(avgDuration == null ? '-' : avgDuration.round().toString(), align: pw.Alignment.center)]),
        pw.TableRow(children: [cell('Duración total'), cell(_formatDuration(totalDuration))]),
        pw.TableRow(children: [cell('Síntomas más frecuentes'), cell(symptomsSummary(symptomsCounts))]),
      ],
    );

    final detailTable = pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: pdfLine, width: .6),
      columnWidths: const {
        0: pw.FixedColumnWidth(82),
        1: pw.FixedColumnWidth(36),
        2: pw.FixedColumnWidth(48),
        3: pw.FixedColumnWidth(62),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(2.0),
        6: pw.FlexColumnWidth(2.0),
      },
      cellStyle: const pw.TextStyle(fontSize: 9.8),
      cellAlignments: const {
        0: pw.Alignment.topLeft,
        1: pw.Alignment.topLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.topLeft,
        5: pw.Alignment.topLeft,
        6: pw.Alignment.topLeft,
      },
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: pdfNavy),
      headerCellDecoration: pw.BoxDecoration(color: _pdfIce),
      headers: ['Fecha', 'Hora', 'Intensidad', 'Duración (seg)', 'Desencadenante', 'Síntomas', 'Notas'],
      data: crises
          .map((c) => [
                df.format(c.date),
                tf.format(c.date),
                c.intensity.toInt().toString(),
                c.duration.toString(),
                c.trigger.isEmpty ? '-' : c.trigger,
                c.symptoms.isEmpty ? '-' : c.symptoms.join(', '),
                c.notes.trim().isEmpty ? '-' : c.notes.trim(),
              ])
          .toList(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
        ),
        build: (ctx) => [
          pw.Text('Reporte de Crisis - $userName',
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: pdfNavy)),
          pw.SizedBox(height: 4),
          pw.Container(height: 1, color: pdfLine),
          pw.SizedBox(height: 4),
          pw.Text('Generado el: ${DateFormat.yMMMMd('es_CL').add_Hm().format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
          pw.Text(
              'Período: ${DateFormat.yMMMd('es_CL').format(start)} – ${DateFormat.yMMMd('es_CL').format(end.subtract(const Duration(days: 1)))}',
              style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
          pw.SizedBox(height: 10),
          pw.Text('Resumen',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfNavy)),
          pw.SizedBox(height: 6),
          summaryTable,
          pw.SizedBox(height: 12),
          pw.Text('Detalle de Crisis',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfNavy)),
          pw.SizedBox(height: 6),
          detailTable,
        ],
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final name =
          "historial_auna_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";
      final file = File("${dir.path}/$name");
      await file.writeAsBytes(await pdf.save());
      final res = await OpenFile.open(file.path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF guardado en Documentos ($name)')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error exportando PDF: ${msg.length > 100 ? msg.substring(0, 100) : msg}')),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = (m % 60).toString().padLeft(2, '0');
      return '${h}h ${mm}m';
    }
    return '${m}m ${s}s';
  }

  // ===== Sheet del Amuleto (con/ sin calibración según flag)
  void _showAmuletoSheet() {
    final conectado = _estadoConexion == 'Conectado';
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: _bg,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: _sx(context, 12),
            right: _sx(context, 12),
            bottom: _sx(context, 12),
            top: _sx(context, 6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  conectado ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                  color: _navy,
                ),
                title: Text(conectado ? 'Conectado' : _estadoConexion),
                subtitle: Text(conectado
                    ? (kUseContinuousFSR ? 'Recibiendo datos del amuleto'
                                          : 'Recibiendo eventos del amuleto')
                    : 'Toca para conectar'),
                onTap: conectado ? null : _iniciarConexion,
              ),

              if (conectado && kUseContinuousFSR) ...[
                const Divider(height: 8),
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Calibración de presión'),
                  subtitle: Text(_valorMaximoDolor == 0
                      ? 'Sin calibrar'
                      : 'Máximo guardado: $_valorMaximoDolor'),
                ),
                if (_estaCalibrando) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: _sx(context, 6)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Presiona con tu fuerza máxima…',
                            style: TextStyle(color: _navy.withOpacity(.85)),
                          ),
                        ),
                        Text('Muestras: ${_valoresCalibracion.length}'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _finalizarCalibracion,
                          child: const Text('Terminar calibración'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _iniciarCalibracion,
                          child: const Text('Iniciar calibración'),
                        ),
                      ),
                      SizedBox(width: _sx(context, 10)),
                      OutlinedButton(
                        onPressed: _valorMaximoDolor == 0 ? null : _reiniciarCalibracion,
                        child: const Text('Reiniciar'),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: _sx(context, 8)),
                if (_valorMaximoDolor > 0)
                  _GlassSurface(
                    child: Row(
                      children: [
                        const Icon(Icons.healing, color: _navy),
                        SizedBox(width: _sx(context, 8)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nivel actual'),
                              SizedBox(height: _sx(context, 4)),
                              LinearProgressIndicator(
                                value: _nivelDolor / 10.0,
                                minHeight: _sx(context, 8),
                                borderRadius: BorderRadius.circular(_sx(context, 8)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: _sx(context, 10)),
                        Text('$_nivelDolor/10',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],

              if (conectado)
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: const Text('Desconectar'),
                  onTap: () {
                    Navigator.pop(context);
                    _desconectar();
                  },
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final vgap = _sx(context, 12);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            _sx(context, 16),
            _sx(context, 10),
            _sx(context, 16),
            _sx(context, 24),
          ),
          child: Column(
            children: [
              Text(
                'Configuración',
                style: TextStyle(
                  fontSize: _sx(context, 24),
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              SizedBox(height: _sx(context, 4)),
              Text(
                'Accede a todas las funciones',
                style: TextStyle(
                  fontSize: _sx(context, 13),
                  color: _navy.withOpacity(0.7),
                ),
              ),
              SizedBox(height: _sx(context, 10)),
              _ActionCard(
                icon: Icons.bluetooth,
                title: 'Amuleto Bluetooth',
                subtitle: _estadoConexion == 'Conectado'
                    ? (kUseContinuousFSR
                        ? (_valorMaximoDolor == 0
                            ? 'Conectado — sin calibración'
                            : 'Conectado — nivel ${_nivelDolor}/10')
                        : 'Conectado — recibiendo eventos')
                    : (_estadoConexion == 'Buscando...' || _estadoConexion == 'Conectando...'
                        ? _estadoConexion
                        : 'Conectar y configurar'),
                onTap: _showAmuletoSheet,
              ),
              SizedBox(height: vgap),
              _ActionCard(
                icon: Icons.person_add_alt_1,
                title: 'Contacto de Emergencia',
                subtitle: 'Configura un contacto para notificar',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función no implementada')),
                ),
              ),
              SizedBox(height: vgap),
              _ActionCard(
                icon: Icons.download_outlined,
                title: 'Exportar Historial',
                subtitle: 'Descargar datos en PDF',
                onTap: _pickAndExportPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
