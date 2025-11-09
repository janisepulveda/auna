// lib/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ⬅️ Ajusta este import si tu archivo está en otra ruta
import 'user_provider.dart';

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// BLE
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ===== BLE (sin cambios de lógica) =====
  final _ble = FlutterReactiveBle();
  String _estadoConexion = 'Desconectado';
  final String _nombreEsp32 = 'Auna';
  bool _estaCalibrando = false;
  List<int> _valoresCalibracion = [];
  int _valorMaximoDolor = 0;
  final Uuid _uuidServicio = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid _uuidCaracteristica = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  StreamSubscription? _suscripcionEscaneo;
  StreamSubscription? _suscripcionConexion;
  StreamSubscription? _suscripcionDatos;
  String? _connectedDeviceId;

  @override
  void initState() {
    super.initState();
    _cargarValorMaximo();
    _ble.connectedDeviceStream.listen((update) {
      if (!mounted) return;
      if (update.connectionState == DeviceConnectionState.connected) {
        setState(() {
          _estadoConexion = 'Conectado';
          _connectedDeviceId = update.deviceId;
          _leerDatos(update.deviceId);
        });
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        if (update.deviceId == _connectedDeviceId) {
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
    } catch (e) {
      debugPrint("Error cargando valor máximo: $e");
    }
  }

  void _guardarValorMaximo(int valor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('valorMaximoDolor', valor);
    } catch (e) {
      debugPrint("Error guardando valor máximo: $e");
    }
  }

  Future<bool> _solicitarPermisos() async {
    Map<Permission, PermissionStatus> statuses = {};
    final permissionsToRequest = <Permission>[];

    if (Platform.isAndroid) {
      permissionsToRequest.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ]);
    } else if (Platform.isIOS) {
      permissionsToRequest.add(Permission.bluetooth);
    }

    if (permissionsToRequest.isNotEmpty) {
      statuses = await permissionsToRequest.request();
    }

    final granted = statuses.values.every((s) => s.isGranted);
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
      if (mounted) setState(() => _estadoConexion = 'Permisos denegados');
      return;
    }

    _suscripcionEscaneo = _ble.scanForDevices(withServices: [_uuidServicio]).listen((device) {
      if (device.name == _nombreEsp32) {
        _suscripcionEscaneo?.cancel();
        if (mounted) setState(() => _estadoConexion = 'Conectando...');
        _conectarDispositivo(device.id);
      }
    }, onError: (e) {
      debugPrint('Error scan: $e');
      if (mounted) setState(() => _estadoConexion = 'Error escaneo');
    });

    Future.delayed(const Duration(seconds: 15), () {
      if (_estadoConexion == 'Buscando...' && mounted) {
        _suscripcionEscaneo?.cancel();
        setState(() => _estadoConexion = 'No encontrado');
      }
    });
  }

  void _conectarDispositivo(String deviceId) {
    _suscripcionConexion = _ble
        .connectToDevice(id: deviceId, connectionTimeout: const Duration(seconds: 20))
        .listen((update) {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connectedDeviceId = deviceId;
        _leerDatos(deviceId);
      }
    }, onError: (e) {
      debugPrint('Error conexión $deviceId: $e');
      if (mounted) setState(() => _estadoConexion = 'Error conexión');
    });
  }

  void _leerDatos(String deviceId) {
    final ch = QualifiedCharacteristic(
      serviceId: _uuidServicio,
      characteristicId: _uuidCaracteristica,
      deviceId: deviceId,
    );
    _suscripcionDatos?.cancel();
    _suscripcionDatos = _ble.subscribeToCharacteristic(ch).listen((data) {
      if (_estaCalibrando && mounted) {
        try {
          final s = utf8.decode(data);
          final v = int.tryParse(s);
          if (v != null) {
            _valoresCalibracion.add(v);
            setState(() {});
          }
        } catch (e) {
          debugPrint('BLE decode: $e');
        }
      }
    }, onError: (e) {
      if (mounted) setState(() => _estadoConexion = 'Error lectura');
    });
  }

  void _iniciarCalibracion() {
    if (_estadoConexion != 'Conectado') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero conecta el amuleto.')));
      return;
    }
    setState(() {
      _estaCalibrando = true;
      _valoresCalibracion = [];
    });

    final t = Timer(const Duration(seconds: 5), _finalizarCalibracion);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (_, __) => AlertDialog(
          title: const Text("Calibrando..."),
          content: Text("Presiona el amuleto con fuerza máxima (5 seg).\nLecturas: ${_valoresCalibracion.length}"),
          actions: [
            TextButton(onPressed: () { t.cancel(); _finalizarCalibracion(); }, child: const Text("Finalizar Ahora")),
          ],
        ),
      ),
    ).then((_) { t.cancel(); if (_estaCalibrando && mounted) setState(() => _estaCalibrando = false); });
  }

  void _finalizarCalibracion() {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
    if (!_estaCalibrando || !mounted) return;
    setState(() => _estaCalibrando = false);
    if (_valoresCalibracion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calibración cancelada: sin datos.')));
      return;
    }
    try {
      final maxv = _valoresCalibracion.reduce(max);
      setState(() => _valorMaximoDolor = maxv);
      _guardarValorMaximo(_valorMaximoDolor);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calibrado. Valor máximo: $maxv')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al procesar datos.')));
    }
  }

  void _desconectar() async {
    await _suscripcionDatos?.cancel();
    await _suscripcionConexion?.cancel();
    _suscripcionDatos = null; _suscripcionConexion = null;
    if (mounted) setState(() { _estadoConexion = 'Desconectado'; _connectedDeviceId = null; });
  }

  // ====== PDF AUNA (diagramación referencia) ======

  Future<void> _pickAndExportPdf() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Exportar PDF'), subtitle: Text('Elige el período')),
            ListTile(leading: const Icon(Icons.all_inbox), title: const Text('Todo el historial'), onTap: () => Navigator.pop(ctx, 'all')),
            ListTile(leading: const Icon(Icons.calendar_view_month), title: const Text('Mes actual'), onTap: () => Navigator.pop(ctx, 'month')),
            ListTile(leading: const Icon(Icons.calendar_today), title: const Text('Últimos 30 días'), onTap: () => Navigator.pop(ctx, '30')),
            ListTile(leading: const Icon(Icons.date_range), title: const Text('Elegir rango…'), onTap: () => Navigator.pop(ctx, 'range')),
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
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 5),
        initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      );
      if (!mounted) return;
      if (picked == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No seleccionaste rango.')));
        return;
      }
      from = picked.start;
      to = picked.end.add(const Duration(days: 1));
    }

    await _exportHistoryToPdf(from: from, to: to);
  }

  PdfColor get _aunaNavy => PdfColor.fromInt(0xFF38455C);
  PdfColor get _aunaIce  => PdfColor.fromInt(0xFFE6F1F5);
  PdfColor get _aunaLine => PdfColor.fromInt(0xFFB7C7D1);
  PdfColor get _aunaGrey => PdfColor.fromInt(0xFF6B7A88);

  Future<void> _exportHistoryToPdf({DateTime? from, DateTime? to}) async {
    final pdf = pw.Document();
    if (!mounted) return;

    try { await initializeDateFormatting('es_CL', null); Intl.defaultLocale ??= 'es_CL'; } catch (_) {}

    final up = Provider.of<UserProvider>(context, listen: false);
    final all = up.registeredCrises.toList();
    final userName = up.user?.name ?? 'Usuario Auna';

    final start = from ?? DateTime.fromMillisecondsSinceEpoch(0);
    final end   = to   ?? DateTime.now();

    final crises = all.where((c) => c.date.isAfter(start) && c.date.isBefore(end)).toList();
    if (crises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay crisis en el período seleccionado.')));
      return;
    }

    crises.sort((a, b) => a.date.compareTo(b.date));
    final df = DateFormat.yMMMMd('es_CL');
    final tf = DateFormat.Hm('es_CL');

    // Resumen
    final avgIntensity = crises.fold<double>(0, (a, c) => a + c.intensity.toDouble()) / crises.length;
    final durations = crises.map((c) => c.duration).where((d) => d != null && d! > 0).cast<int>().toList();
    final totalDuration = durations.isEmpty ? 0 : durations.reduce((a, b) => a + b);
    final avgDuration   = durations.isEmpty ? null : durations.reduce((a, b) => a + b) / durations.length;

    int leves = 0, moderados = 0, severos = 0;
    for (final c in crises) {
      final v = c.intensity.toInt();
      if (v <= 3) leves++; else if (v <= 7) moderados++; else severos++;
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

    final symptomsCounts = countSymptoms(crises.expand((c) => (c.symptoms ?? const <String>[])));
    String symptomsSummary(Map<String, int> map, {int take = 6}) {
      if (map.isEmpty) return '-';
      final ord = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return ord.take(take).map((e) => '• ${e.key}: ${e.value}').join('\n');
    }

    String formatDuration(int seconds) {
      final m = seconds ~/ 60, s = seconds % 60;
      if (m >= 60) { final h = m ~/ 60, mm = (m % 60).toString().padLeft(2,'0'); return '${h}h ${mm}m'; }
      return '${m}m ${s}s';
    }

    String rangoTxt() {
      if (from == null && to == null) return 'Período: todo el historial';
      return 'Período: ${DateFormat.yMMMd('es_CL').format(start)} – ${DateFormat.yMMMd('es_CL').format(end)}';
    }

    pw.Widget headCell(String t) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      color: _aunaIce,
      child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: _aunaNavy)),
    );

    pw.Widget cell(String t, {pw.Alignment align = pw.Alignment.topLeft, double fs = 10}) =>
      pw.Container(padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8), alignment: align,
        child: pw.Text(t, style: pw.TextStyle(fontSize: fs), softWrap: true),
      );

    final summaryTable = pw.Table(
      border: pw.TableBorder.all(color: _aunaLine, width: .6),
      columnWidths: const {0: pw.FixedColumnWidth(200), 1: pw.FlexColumnWidth(1)},
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

    final detailTable = pw.Table(
      border: pw.TableBorder.all(color: _aunaLine, width: .6),
      columnWidths: const {
        0: pw.FixedColumnWidth(90),
        1: pw.FixedColumnWidth(40),
        2: pw.FixedColumnWidth(55),
        3: pw.FixedColumnWidth(70),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(2.2),
        6: pw.FlexColumnWidth(2.2),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
      children: [
        pw.TableRow(children: [
          headCell('Fecha'), headCell('Hora'), headCell('Intensidad'), headCell('Duración (seg)'),
          headCell('Desencadenante'), headCell('Síntomas'), headCell('Notas'),
        ]),
        for (final c in crises) pw.TableRow(children: [
          cell(df.format(c.date)), cell(tf.format(c.date)),
          cell(c.intensity.toInt().toString(), align: pw.Alignment.center),
          cell((c.duration ?? 0).toString(), align: pw.Alignment.center),
          cell(c.trigger ?? '-'),
          cell((c.symptoms == null || c.symptoms!.isEmpty) ? '-' : c.symptoms!.join(', ')),
          cell((c.notes?.trim().isEmpty ?? true) ? '-' : c.notes!.trim()),
        ]),
      ],
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 9, color: _aunaGrey)),
        ),
        build: (ctx) => [
          pw.Text('Reporte de Crisis - $userName',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _aunaNavy)),
          pw.SizedBox(height: 6),
          pw.Container(height: 1, color: _aunaLine),
          pw.SizedBox(height: 6),
          pw.Text('Generado el: ${DateFormat.yMMMMd('es_CL').add_Hm().format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: _aunaGrey)),
          pw.SizedBox(height: 2),
          pw.Text(rangoTxt(), style: pw.TextStyle(fontSize: 10, color: _aunaGrey)),
          pw.SizedBox(height: 16),

          pw.Text('Resumen', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _aunaNavy)),
          pw.SizedBox(height: 6),
          summaryTable,
          pw.SizedBox(height: 18),

          pw.Text('Detalle de Crisis', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _aunaNavy)),
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

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF guardado en Documentos ($name)'),
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exportando PDF: ${msg.length > 100 ? msg.substring(0, 100) : msg}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estaConectado = _estadoConexion == 'Conectado';
    return Scaffold(
      appBar: AppBar(
        title: Consumer<UserProvider>(
          builder: (context, up, child) {
            final userName = up.user?.name ?? 'Usuario';
            final userEmail = up.user?.email ?? 'sin-email@auna.app';
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(userName, style: const TextStyle(fontSize: 18)),
                Text(userEmail, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            );
          },
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsCard(
            icon: Icons.bluetooth,
            title: 'Conectar Amuleto',
            subtitle: 'Estado: $_estadoConexion',
            trailing: estaConectado
                ? TextButton(onPressed: _desconectar, child: const Text('Desconectar'))
                : ElevatedButton(
                    onPressed: (_estadoConexion == 'Buscando...' || _estadoConexion == 'Conectando...') ? null : _iniciarConexion,
                    child: Text(
                      _estadoConexion == 'Desconectado' || _estadoConexion == 'No encontrado' ||
                      _estadoConexion.startsWith('Error') || _estadoConexion == 'Permisos denegados'
                        ? 'Buscar Amuleto' : _estadoConexion,
                    ),
                  ),
          ),
          if (estaConectado)
            _buildSettingsCard(
              icon: Icons.tune,
              title: 'Calibración del Sensor',
              subtitle: _valorMaximoDolor == 0 ? 'Realiza la calibración inicial' : 'Calibrado. Máx: $_valorMaximoDolor',
              trailing: TextButton(
                onPressed: _estaCalibrando ? null : _iniciarCalibracion,
                child: Text(_valorMaximoDolor == 0 ? 'Iniciar Calibración' : 'Recalibrar'),
              ),
            ),
          _buildSettingsCard(
            icon: Icons.person_add_alt_1,
            title: 'Contacto de Emergencia',
            subtitle: 'Configura un contacto para notificar',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función no implementada'))),
          ),
          _buildSettingsCard(
            icon: Icons.download,
            title: 'Exportar Historial',
            subtitle: 'Elige período y genera PDF',
            trailing: const Icon(Icons.download_done),
            onTap: _pickAndExportPdf,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
