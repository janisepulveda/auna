// lib/settings_screen.dart

import 'dart:async';
//import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
//import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
//import 'package:url_launcher/url_launcher.dart';

import 'user_provider.dart';
//import 'notification_service.dart';
import 'ble_manager.dart'; // <-- usamos el servicio global ble

// ===== paleta de colores base para la pantalla de ajustes =====
const _navy = Color(0xFF38455C);
const _bg = Color(0xFFF0F7FA);

// ===== utilidad de escala: ajusta medidas en función del ancho del teléfono =====
double _sx(BuildContext c, [double v = 1]) {
  final w = MediaQuery.of(c).size.width;
  final s = (w / 390).clamp(.75, 0.95);
  return v * s;
}

// ===== estilos "glass": contenedor con gradiente, borde y sombra suaves =====
BoxDecoration _glassContainer({required BuildContext context}) => BoxDecoration(
      borderRadius: BorderRadius.circular(_sx(context, 16)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.15),
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.48), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFAABEDC).withValues(alpha: 0.12),
          blurRadius: _sx(context, 10),
          offset: Offset(0, _sx(context, 5)),
        ),
      ],
    );

// ===== superficie glass reutilizable (desenfoque + contenedor) =====
class _GlassSurface extends StatelessWidget {
  final Widget child;
  const _GlassSurface({required this.child});

  // padding por defecto dependiente de la escala
  static EdgeInsets _defaultPad(BuildContext c) => EdgeInsets.all(_sx(c, 10));

  @override
  Widget build(BuildContext context) {
    final r = _sx(context, 16);
    return ClipRRect(
      // recorta bordes redondeados para que el blur no se salga del contenedor
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        // aplica desenfoque al fondo para efecto glass
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

// ===== tarjeta de acción: icono + título + subtítulo + flecha =====
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
    // tamaños sensibles al ancho del dispositivo
    final iconSize = _sx(context, 32);
    final tileSide = _sx(context, 48);
    final gap = _sx(context, 10);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // toda el área responde al tap
      child: _GlassSurface(
        child: Row(
          children: [
            // bloque del icono con su propio blur y gradiente
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
                        Colors.white.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  child: Icon(icon, color: _navy, size: iconSize),
                ),
              ),
            ),
            SizedBox(width: gap),
            // textos de título y subtítulo con elipsis
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // título fuerte
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
                  // subtítulo descriptivo
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _navy.withValues(alpha: 0.72),
                      fontSize: _sx(context, 12.5),
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _sx(context, 6)),
            // chevron de navegación
            Icon(Icons.chevron_right, color: _navy.withValues(alpha: 0.7), size: _sx(context, 22)),
          ],
        ),
      ),
    );
  }
}

// ===================== settings screen =====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ===== helpers de color para el pdf (coinciden con la paleta visual) =====
  PdfColor get _pdfNavy => const PdfColor.fromInt(0xFF38455C);
  PdfColor get _pdfIce => const PdfColor.fromInt(0xFFE6F1F5);
  PdfColor get _pdfLine => const PdfColor.fromInt(0xFFB7C7D1);
  PdfColor get _pdfGrey => const PdfColor.fromInt(0xFF6B7A88);

  // ===== util: contar síntomas repetidos para resumen en pdf =====
  Map<String, int> countSymptoms(Iterable<String> xs) {
    final m = <String, int>{};
    for (final raw in xs) {
      final k = raw.trim();
      if (k.isEmpty) continue;
      m.update(k, (v) => v + 1, ifAbsent: () => 1);
    }
    return m;
  }

  // ===== selector de periodo antes de exportar el pdf =====
  Future<void> _pickAndExportPdf() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true, // tirador para sugerir que se puede arrastrar
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

    // resuelve rango según la opción elegida
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
      // sumamos 1 día al final para incluirlo de forma exclusiva
      to = picked.end.add(const Duration(days: 1));
    }
    await _exportHistoryToPdf(from: from, to: to);
  }

  // ===== genera y guarda el pdf en documentos; intenta abrirlo con open_file_plus =====
  Future<void> _exportHistoryToPdf({DateTime? from, DateTime? to}) async {
    final pdf = pw.Document();

    // prepara localización y formato de fechas
    if (!mounted) return;
    try {
      await initializeDateFormatting('es_CL', null);
      Intl.defaultLocale ??= 'es_CL';
    } catch (_) {}
    if (!mounted) return;

    // obtiene datos del usuario y filtra por rango
    final up = Provider.of<UserProvider>(context, listen: false);
    final all = up.registeredCrises.toList();
    final userName = up.user?.name ?? 'Usuario Auna';
    final start = from ?? DateTime.fromMillisecondsSinceEpoch(0);
    final end = to ?? DateTime.now();

    final crises = all.where((c) => c.date.isAfter(start) && c.date.isBefore(end)).toList();
    if (crises.isEmpty) {
      // feedback si no hay datos en el rango seleccionado
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay crisis en el período seleccionado.')),
      );
      return;
    }

    // ordena y calcula indicadores básicos
    crises.sort((a, b) => a.date.compareTo(b.date));
    final df = DateFormat.yMMMMd('es_CL');
    final tf = DateFormat.Hm('es_CL');

    final totalIntensity = crises.fold<double>(0, (a, c) => a + c.intensity.toDouble());
    final avgIntensity = totalIntensity / crises.length;

    final durations =
        crises.map((c) => c.duration).whereType<int>().where((d) => d > 0).toList();
    final totalDuration = durations.isEmpty ? 0 : durations.reduce((a, b) => a + b);
    final double? avgDuration =
        durations.isEmpty ? null : totalDuration / durations.length;

    // buckets de intensidad (para un vistazo rápido)
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

    // resumen de síntomas más frecuentes
    final symptomsCounts = countSymptoms(crises.expand((c) => c.symptoms));
    String symptomsSummary(Map<String, int> map, {int take = 6}) {
      if (map.isEmpty) return '-';
      final ord = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return ord.take(take).map((e) => '• ${e.key}: ${e.value}').join('\n');
    }

    // alias locales para colores pdf
    final pdfNavy = _pdfNavy, pdfIce = _pdfIce, pdfLine = _pdfLine, pdfGrey = _pdfGrey;

    // helpers para celdas de tabla
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

    // tabla de resumen (indicadores generales)
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

    // tabla de detalle de crisis (listado con columnas clave)
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

    // página principal del reporte con encabezado, resumen y detalle
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: _pdfGrey)),
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

    // guarda el pdf en la carpeta de documentos de la app e intenta abrirlo
    try {
      final dir = await getApplicationDocumentsDirectory();
      final name =
          "historial_auna_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";
      final file = File("${dir.path}/$name");
      await file.writeAsBytes(await pdf.save());
      final res = await OpenFile.open(file.path);
      // si no se puede abrir, informa dónde quedó el archivo
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF guardado en Documentos ($name)')),
        );
      }
    } catch (e) {
      // feedback de error acotado (máx 100 caracteres)
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

  // ===== convierte segundos a formato legible (ej. 1h 05m, 12m 30s) =====
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

  // ===== hoja inferior para administrar conexión del amuleto (usa blemanager) =====
  void _showAmuletoSheet() {
    final bleWatch = context.watch<BleManager>(); // escucha cambios de estado
    final ble = context.read<BleManager>();       // instancia para ejecutar acciones
    final conectado = bleWatch.isConnected;

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
              // tile principal: conectar o mostrar estado actual
              ListTile(
                leading: Icon(
                  conectado ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                  color: _navy,
                ),
                title: Text(conectado ? 'Conectado' : bleWatch.connectionStateLabel),
                subtitle: Text(conectado
                    ? 'Recibiendo eventos del amuleto'
                    : 'Toca para conectar'),
                onTap: conectado ? null : ble.connect,
              ),
              // acción secundaria: desconectar cuando ya está conectado
              if (conectado)
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: const Text('Desconectar'),
                  onTap: () {
                    Navigator.pop(context);
                    ble.disconnect();
                  },
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== ui principal de la pantalla de ajustes =====================
  @override
  Widget build(BuildContext context) {
    final vgap = _sx(context, 12);
    final ble = context.watch<BleManager>();

    // subtítulo dinámico para el estado del amuleto
    final subtitleBle = ble.isConnected
        ? 'Conectado — recibiendo eventos'
        : (ble.connectionStateLabel.startsWith('Reconectando')
            ? ble.connectionStateLabel
            : (ble.connectionStateLabel == 'Desconectado'
                ? 'Conectar y configurar'
                : ble.connectionStateLabel));

    return Scaffold(
      backgroundColor: _bg, // fondo celeste muy suave
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
              // título de la pantalla
              Text(
                'Configuración',
                style: TextStyle(
                  fontSize: _sx(context, 24),
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              SizedBox(height: _sx(context, 4)),
              // subtítulo descriptivo
              Text(
                'Accede a todas las funciones',
                style: TextStyle(
                  fontSize: _sx(context, 13),
                  color: _navy.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: _sx(context, 10)),
              // tarjeta: estado/conexión del amuleto
              _ActionCard(
                icon: Icons.bluetooth,
                title: 'Amuleto Bluetooth',
                subtitle: subtitleBle,
                onTap: _showAmuletoSheet,
              ),
              SizedBox(height: vgap),
              // tarjeta: contacto de emergencia (placeholder)
              _ActionCard(
                icon: Icons.person_add_alt_1,
                title: 'Contacto de Emergencia',
                subtitle: 'Configura un contacto para notificar',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función no implementada')),
                ),
              ),
              SizedBox(height: vgap),
              // tarjeta: exportar historial a pdf
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
