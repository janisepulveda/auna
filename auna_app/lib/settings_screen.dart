// lib/settings_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui; // Renombramos para evitar conflicto

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
import 'package:shared_preferences/shared_preferences.dart';

import 'user_provider.dart';
import 'notification_service.dart'; // <-- ¡IMPORTA EL SERVICIO DE NOTIFICACIÓN!

// ===== Paleta
const _navy = Color(0xFF38455C);
const _bg   = Color(0xFFF0F7FA);

// ===== Utilidad de escala
double _sx(BuildContext c, [double v = 1]) {
  final w = MediaQuery.of(c).size.width;
  final s = (w / 390).clamp(.75, 0.95);
  return v * s;
}

// ===== Glass helpers (Corregido con .withOpacity())
BoxDecoration _glassContainer({required BuildContext context}) => BoxDecoration(
  borderRadius: BorderRadius.circular(_sx(context, 16)),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.35), // Ajustado desde .15
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

// ===== Card de acción (Corregido con .withOpacity())
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
  bool _estaCalibrando = false;
  List<int> _valoresCalibracion = [];
  int _valorMaximoDolor = 0;
  final Uuid _uuidServicio = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid _uuidCaracteristica = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  StreamSubscription<DiscoveredDevice>? _suscripcionEscaneo;
  StreamSubscription<ConnectionStateUpdate>? _suscripcionConexion;
  StreamSubscription<List<int>>? _suscripcionDatos;
  String? _connectedDeviceId;

  // ¡NUEVO! Control para evitar spam de notificaciones
  bool _crisisNotificada = false;

  @override
  void initState() {
    super.initState();
    _cargarValorMaximo();
    _ble.connectedDeviceStream.listen((update) {
       if(!mounted) return;
       if(update.connectionState == DeviceConnectionState.connected){
         setState(() {
           _estadoConexion = 'Conectado';
           _connectedDeviceId = update.deviceId;
           _leerDatos(update.deviceId);
         });
       } else if (update.connectionState == DeviceConnectionState.disconnected) {
         if(update.deviceId == _connectedDeviceId) {
           setState(() {
             _estadoConexion = 'Desconectado';
             _connectedDeviceId = null;
             _suscripcionDatos?.cancel();
           });
         }
       }
    });
  }

  @override
  void dispose() {
    _suscripcionEscaneo?.cancel();
    _suscripcionConexion?.cancel();
    _suscripcionDatos?.cancel();
    super.dispose();
  }

  void _cargarValorMaximo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _valorMaximoDolor = prefs.getInt('valorMaximoDolor') ?? 0);
      }
    } catch (_) {}
  }

  void _guardarValorMaximo(int valor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('valorMaximoDolor', valor);
    } catch (_) {}
  }

  Future<bool> _solicitarPermisos() async {
    Map<Permission, PermissionStatus> statuses = {};
    List<Permission> permissionsToRequest = [];
    if (Platform.isAndroid) {
      permissionsToRequest.addAll([
          Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse,
      ]);
    } else if (Platform.isIOS) {
       permissionsToRequest.add(Permission.bluetooth);
    }
    if(permissionsToRequest.isNotEmpty) {
        statuses = await permissionsToRequest.request();
    }
    bool granted = statuses.values.every((status) => status.isGranted);
    if (!granted && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Permisos de Bluetooth/Ubicación son necesarios.')),
       );
    }
    return granted;
  }

  void _iniciarConexion() async {
    await _suscripcionEscaneo?.cancel();
    await _suscripcionConexion?.cancel();
    await _suscripcionDatos?.cancel();
    _suscripcionEscaneo = null; _suscripcionConexion = null; _suscripcionDatos = null;
    if (!mounted) return;
    setState(() { _estadoConexion = 'Buscando...'; _connectedDeviceId = null; });
    final ok = await _solicitarPermisos();
    if (!ok) { if (mounted) setState(() => _estadoConexion = 'Permisos denegados'); return; }
    
    bool found = false;
    _suscripcionEscaneo = _ble.scanForDevices(withServices: [_uuidServicio]).listen((device) {
      if (device.name == _nombreEsp32) {
        found = true;
        _suscripcionEscaneo?.cancel();
        if (mounted) setState(() => _estadoConexion = 'Conectando...');
        _conectarDispositivo(device.id);
      }
    }, onError: (_) { if (mounted) setState(() => _estadoConexion = 'Error escaneo'); });

    Future.delayed(const Duration(seconds: 8), () async {
      if (!mounted || found) return;
      await _suscripcionEscaneo?.cancel();
      _suscripcionEscaneo = _ble.scanForDevices(withServices: const []).listen((device) {
        if (device.name == _nombreEsp32) {
          found = true;
          _suscripcionEscaneo?.cancel();
          if (mounted) setState(() => _estadoConexion = 'Conectando...');
          _conectarDispositivo(device.id);
        }
      }, onError: (_) { if (mounted) setState(() => _estadoConexion = 'Error escaneo'); });
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

  // --- ¡FUNCIÓN _leerDatos ACTUALIZADA CON LÓGICA DE NOTIFICACIÓN! ---
  void _leerDatos(String deviceId) {
    final ch = QualifiedCharacteristic(
      serviceId: _uuidServicio,
      characteristicId: _uuidCaracteristica,
      deviceId: deviceId,
    );
    _suscripcionDatos?.cancel();
    _suscripcionDatos = _ble.subscribeToCharacteristic(ch).listen((data) {
      if (!mounted) return;
      
      int? valorCrudo;
      try {
        final s = utf8.decode(data);
        valorCrudo = int.tryParse(s);
      } catch (_) { return; } // Error decodificando, ignora el paquete

      if (valorCrudo == null) return; // Dato no es número, ignora

      // Lógica de Calibración
      if (_estaCalibrando) {
        _valoresCalibracion.add(valorCrudo);
        setState(() {}); // refrescar contador en el diálogo
      }
      // Lógica de Detección de Crisis
      else {
        // Umbral: 80% del máximo calibrado
        if (_valorMaximoDolor == 0) return; // No puede detectar si no está calibrado
        double umbral = _valorMaximoDolor * 0.8; 

        // Si supera el umbral Y no hemos notificado ya
        if (valorCrudo > umbral && !_crisisNotificada) {
          debugPrint('¡Crisis detectada por BLE! Valor: $valorCrudo');
          setState(() {
            _crisisNotificada = true; // Marca como notificada
          });

          // 1. Registra una crisis preliminar (vacía)
          final newCrisis = Provider.of<UserProvider>(context, listen: false)
              .registerCrisis(
            intensity: 0, // Preliminar
            duration: 0, // Preliminar
            notes: "Detectada automáticamente por el amuleto.",
            trigger: "Otro", // Default
            symptoms: [], // Vacío
          );

          // 2. Muestra la notificación con el ID de la crisis
          NotificationService().showCrisisNotification(newCrisis);

          // 3. Resetea el flag después de un tiempo (ej. 3 minutos)
          Future.delayed(const Duration(minutes: 3), () {
            if(mounted) setState(() => _crisisNotificada = false);
          });
        }
      }
    }, onError: (_) {
      if (mounted) setState(() => _estadoConexion = 'Error lectura');
    });
  }

  // --- ¡FUNCIÓN _iniciarCalibracion CORREGIDA! ---
  void _iniciarCalibracion() {
    if (_estadoConexion != 'Conectado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero conecta el amuleto.')),
      );
      return;
    }
    setState(() {
      _estaCalibrando = true;
      _valoresCalibracion = [];
    });
    final t = Timer(const Duration(seconds: 5), () {
      if (_estaCalibrando && mounted) {
        _finalizarCalibracion(isManual: false);
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder( // Usamos StatefulBuilder para actualizar solo el diálogo
        builder: (context, setDialogState) {
           // Hacemos que _leerDatos (con su setState) actualice este diálogo
           // Para forzarlo, podemos hacer un truco
           void updateDialog() {
             if(_estaCalibrando && mounted) {
                setDialogState(() {});
             }
           }
           // Volvemos a atachar el listener (esto es un poco hacky pero funciona)
           _suscripcionDatos?.onData((_) => updateDialog());

           return AlertDialog(
              title: const Text("Calibrando..."),
              content: Text(
                "Presiona el amuleto con fuerza máxima (5 seg).\nLecturas: ${_valoresCalibracion.length}",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    t.cancel();
                    _finalizarCalibracion(isManual: true);
                  },
                  child: const Text("Finalizar Ahora"),
                ),
              ],
           );
        }
      ),
    ).then((_) {
      t.cancel();
      if (_estaCalibrando && mounted) {
        setState(() => _estaCalibrando = false);
      }
    });
  }

  void _finalizarCalibracion({bool isManual = false}) {
    if (!isManual && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!_estaCalibrando || !mounted) return;

    setState(() => _estaCalibrando = false);
    if (_valoresCalibracion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibración cancelada: sin datos.')),
      );
      return;
    }
    try {
      final maxv = _valoresCalibracion.reduce(max);
      setState(() => _valorMaximoDolor = maxv);
      _guardarValorMaximo(_valorMaximoDolor);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calibrado. Valor máximo: $maxv')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar datos.')),
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
      });
    }
  }

  // ------- PDF
  PdfColor get _pdfNavy => const PdfColor.fromInt(0xFF38455C);
  PdfColor get _pdfIce  => const PdfColor.fromInt(0xFFE6F1F5);
  PdfColor get _pdfLine => const PdfColor.fromInt(0xFFB7C7D1);
  PdfColor get _pdfGrey => const PdfColor.fromInt(0xFF6B7A88);

  Future<void> _pickAndExportPdf() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile( title: Text('Exportar PDF'), subtitle: Text('Elige el período'), ),
            ListTile( leading: const Icon(Icons.all_inbox), title: const Text('Todo el historial'), onTap: () => Navigator.of(ctx).pop('all'), ),
            ListTile( leading: const Icon(Icons.calendar_view_month), title: const Text('Mes actual'), onTap: () => Navigator.of(ctx).pop('month'), ),
            ListTile( leading: const Icon(Icons.calendar_today), title: const Text('Últimos 30 días'), onTap: () => Navigator.of(ctx).pop('30'), ),
            ListTile( leading: const Icon(Icons.date_range), title: const Text('Elegir rango…'), onTap: () => Navigator.of(ctx).pop('range'), ),
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
        initialDateRange: DateTimeRange( start: now.subtract(const Duration(days: 7)), end: now, ),
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
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('No hay crisis en el período seleccionado.')), );
      return;
    }
    crises.sort((a, b) => a.date.compareTo(b.date));
    final df = DateFormat.yMMMMd('es_CL');
    final tf = DateFormat.Hm('es_CL');
    final totalIntensity = crises.fold<double>(0, (a, c) => a + c.intensity.toDouble());
    final avgIntensity = totalIntensity / crises.length;
    final durations = crises.map((c) => c.duration).whereType<int>().where((d) => d > 0).toList();
    final totalDuration = durations.isEmpty ? 0 : durations.reduce((a, b) => a + b);
    final double? avgDuration = durations.isEmpty ? null : totalDuration / durations.length;
    int leves = 0, moderados = 0, severos = 0;
    for (final c in crises) {
      final v = c.intensity.toInt();
      if (v <= 3) leves++;
      else if (v <= 7) moderados++;
      else severos++;
    }
    Map<String, int> countSymptoms(Iterable<String> xs) {
      final m = <String, int>{};
      for (final s in xs) {
        final k = s.trim();
        if (k.isEmpty) continue;
        m.update(k, (v) => v + 1, ifAbsent: () => 1);
      }
      return m;
    }
    final symptomsCounts = countSymptoms(crises.expand((c) => c.symptoms));
    String symptomsSummary(Map<String, int> map, {int take = 6}) {
      if (map.isEmpty) return '-';
      final ord = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return ord.take(take).map((e) => '• ${e.key}: ${e.value}').join('\n');
    }
    String formatDuration(int seconds) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      if (m >= 60) {
        final h = m ~/ 60;
        final mm = (m % 60).toString().padLeft(2, '0');
        return '${h}h ${mm}m';
      }
      return '${m}m ${s}s';
    }
    final pdfNavy = _pdfNavy, pdfIce = _pdfIce, pdfLine = _pdfLine, pdfGrey = _pdfGrey;
    pw.Widget headCell(String t) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      color: pdfIce,
      child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: pdfNavy)),
    );
    pw.Widget cell(String t, {pw.Alignment align = pw.Alignment.topLeft, double fs = 9.8}) =>
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
        pw.TableRow(children: [cell('Duración total'), cell(formatDuration(totalDuration))]),
        pw.TableRow(children: [cell('Síntomas más frecuentes'), cell(symptomsSummary(symptomsCounts))]),
      ],
    );
    // --- CORREGIDO: Usar TableHelper ---
    final detailTable = pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: pdfLine, width: .6),
      columnWidths: const { 0: pw.FixedColumnWidth(82), 1: pw.FixedColumnWidth(36), 2: pw.FixedColumnWidth(48), 3: pw.FixedColumnWidth(62), 4: pw.FlexColumnWidth(1.2), 5: pw.FlexColumnWidth(2.0), 6: pw.FlexColumnWidth(2.0), },
      cellStyle: const pw.TextStyle(fontSize: 9.8),
      cellAlignments: { 0: pw.Alignment.topLeft, 1: pw.Alignment.topLeft, 2: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.topLeft, 5: pw.Alignment.topLeft, 6: pw.Alignment.topLeft, },
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: pdfNavy),
      headerCellDecoration: pw.BoxDecoration(color: pdfIce),
      headers: ['Fecha', 'Hora', 'Intensidad', 'Duración (seg)', 'Desencadenante', 'Síntomas', 'Notas'],
      data: crises.map((c) => [
          df.format(c.date),
          tf.format(c.date),
          c.intensity.toInt().toString(),
          c.duration.toString(),
          c.trigger.isEmpty ? '-' : c.trigger,
          c.symptoms.isEmpty ? '-' : c.symptoms.join(', '),
          c.notes.trim().isEmpty ? '-' : c.notes.trim(),
      ]).toList(),
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
        ),
        build: (ctx) => [
          pw.Text('Reporte de Crisis - $userName', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: pdfNavy)),
          pw.SizedBox(height: 4), pw.Container(height: 1, color: pdfLine),
          pw.SizedBox(height: 4),
          pw.Text('Generado el: ${DateFormat.yMMMMd('es_CL').add_Hm().format(DateTime.now())}', style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
          pw.Text('Período: ${DateFormat.yMMMd('es_CL').format(start)} – ${DateFormat.yMMMd('es_CL').format(end.subtract(const Duration(days: 1)))}', style: pw.TextStyle(fontSize: 9, color: pdfGrey)),
          pw.SizedBox(height: 10),
          pw.Text('Resumen', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfNavy)),
          pw.SizedBox(height: 6),
          summaryTable,
          pw.SizedBox(height: 12),
          pw.Text('Detalle de Crisis', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfNavy)),
          pw.SizedBox(height: 6),
          detailTable,
        ],
      ),
    );
    try {
      final dir = await getApplicationDocumentsDirectory();
      final name = "historial_auna_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";
      final file = File("${dir.path}/$name");
      await file.writeAsBytes(await pdf.save());
      final res = await OpenFile.open(file.path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('PDF guardado en Documentos ($name)')), );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error exportando PDF: ${msg.length > 100 ? msg.substring(0, 100) : msg}')), );
      }
    }
  }

  // ===== Sheet del Amuleto (compacto)
  void _showAmuletoSheet() {
    final conectado = _estadoConexion == 'Conectado';
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: _bg, // Fondo del sheet
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(conectado ? Icons.bluetooth_connected : Icons.bluetooth_searching, color: _navy),
              title: Text(conectado ? 'Conectado' : _estadoConexion),
              subtitle: Text(conectado ? 'Máximo detectado: $_valorMaximoDolor' : 'Toca para intentar conectar'),
              onTap: conectado ? null : _iniciarConexion,
            ),
            if (conectado)
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Calibrar sensor'),
                onTap: () {
                  Navigator.pop(context);
                  _iniciarCalibracion();
                },
              ),
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
                  color: _navy.withOpacity(0.7), // Corregido .withValues
                ),
              ),
              SizedBox(height: _sx(context, 10)),

              _ActionCard(
                icon: Icons.bluetooth,
                title: 'Amuleto Bluetooth',
                subtitle: _estadoConexion == 'Conectado'
                    ? 'Conectado — Calibrar o desconectar'
                    : (_estadoConexion == 'Buscando...' || _estadoConexion == 'Conectando...'
                        ? _estadoConexion
                        : 'Conectar dispositivo'),
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