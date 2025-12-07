// lib/settings_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import 'user_provider.dart';
import 'ble_manager.dart';

// --- PALETA APP (UI) ---
const _navy = Colors.white; 
const _bg = Color(0xFF061D17); 
const _lotusGreen = Color(0xFF748204);

// --- UTILIDADES UI ---
double _sx(BuildContext c, [double v = 1]) {
  final w = MediaQuery.of(c).size.width;
  final s = (w / 390).clamp(0.75, 0.95);
  return v * s;
}

// Estilos Glass
BoxDecoration _glassContainer({required BuildContext context}) => BoxDecoration(
  borderRadius: BorderRadius.circular(24),
  color: Colors.black.withValues(alpha: 0.18),
  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
);

// Tarjeta de acción
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
    const double iconSize = 28;
    const double tileSide = 48;
    const double gap = 16;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _glassContainer(context: context),
            child: Row(
              children: [
                Container(
                  width: tileSide,
                  height: tileSide,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: Colors.white, size: iconSize),
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
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _navy.withValues(alpha: 0.7),
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: _navy.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  // --- DIÁLOGO DE CONTACTO (NOMBRE + TELÉFONO) ---
  void _showContactDialog() {
    final up = Provider.of<UserProvider>(context, listen: false);
    
    // Preparar teléfono (quitar prefijo visualmente)
    String currentNumber = up.emergencyPhone ?? '';
    const String prefix = '+56 9 ';
    if (currentNumber.startsWith(prefix)) {
      currentNumber = currentNumber.substring(prefix.length);
    }

    final phoneController = TextEditingController(text: currentNumber);
    // Nuevo: Controlador para el nombre
    final nameController = TextEditingController(text: up.emergencyName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Contacto de Emergencia', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configura a quién quieres notificar en caso de crisis.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            
            // CAMPO NOMBRE
            const Text('Nombre (Ej: Mamá, Pedro)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Nombre del contacto',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _lotusGreen),
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // CAMPO TELÉFONO
            const Text('Número', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                prefixText: prefix, 
                prefixStyle: const TextStyle(
                  color: Colors.white70, 
                  fontSize: 16, 
                  fontWeight: FontWeight.bold
                ),
                hintText: '1234 5678', 
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _lotusGreen),
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              final cleanNumber = phoneController.text.trim();
              final cleanName = nameController.text.trim();

              if (cleanNumber.isNotEmpty) {
                // Guardar ambos
                up.setEmergencyContact(cleanName, '$prefix$cleanNumber');
              } else {
                // Si borra el número, borramos el contacto entero
                up.setEmergencyContact(null, null);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contacto guardado')),
              );
            },
            child: const Text('Guardar', style: TextStyle(color: _lotusGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
      backgroundColor: _bg,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Exportar PDF', style: TextStyle(color: Colors.white)),
              subtitle: Text('Elige el período', style: TextStyle(color: Colors.white70)),
            ),
            ListTile(
              leading: const Icon(Icons.all_inbox, color: Colors.white),
              title: const Text('Todo el historial', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(ctx).pop('all'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_month, color: Colors.white),
              title: const Text('Mes actual', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(ctx).pop('month'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.white),
              title: const Text('Últimos 30 días', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(ctx).pop('30'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: Colors.white),
              title: const Text('Elegir rango…', style: TextStyle(color: Colors.white)),
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
    final now = DateTime.now();

    if (choice == 'month') {
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month + 1, 1);
    } else if (choice == '30') {
      to = now;
      from = to.subtract(const Duration(days: 30));
    } else if (choice == 'range') {
      if (!mounted) return;
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

  // --- GENERACIÓN DEL PDF ---
  Future<void> _exportHistoryToPdf({DateTime? from, DateTime? to}) async {
    final pdf = pw.Document();

    if (!mounted) return;
    try {
      await initializeDateFormatting('es_CL', null);
      Intl.defaultLocale ??= 'es_CL';
    } catch (_) {}
    if (!mounted) return;

    final pdfTextMain = PdfColor.fromInt(0xFF111827);
    final pdfTextSub = PdfColor.fromInt(0xFF6B7280);
    final pdfAccent = PdfColor.fromInt(0xFF0F766E);
    final pdfBgLight = PdfColor.fromInt(0xFFF3F4F6);

    final up = Provider.of<UserProvider>(context, listen: false);
    final all = up.registeredCrises.toList();
    final userName = up.user?.name ?? 'Usuario';
    
    final start = from ?? DateTime.fromMillisecondsSinceEpoch(0);
    final end = to ?? DateTime.now();

    final crises = all.where((c) => c.date.isAfter(start) && c.date.isBefore(end)).toList();
    crises.sort((a, b) => b.date.compareTo(a.date));

    if (crises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay crisis en el período seleccionado.')),
      );
      return;
    }

    final totalCrisis = crises.length;
    final totalIntensity = crises.fold<double>(0, (a, c) => a + c.intensity);
    final avgIntensity = totalCrisis > 0 ? totalIntensity / totalCrisis : 0.0;
    
    String durationToLabel(int d) {
      if (d == 15) return 'Segundos';
      if (d == 45) return '< 1 min';
      if (d == 90) return '1-2 min'; 
      if (d == 120) return 'Ráfagas';
      if (d < 60) return '$d seg';
      return '${(d / 60).toStringAsFixed(0)} min';
    }

    int cSegundos = 0;
    int cMenos1 = 0;
    int c1a2 = 0;
    int cRafagas = 0;

    for (var c in crises) {
      final d = c.duration;
      if (d == 15) {
        cSegundos++;
      } else if (d == 45) {
        cMenos1++;
      } else if (d == 90) {
        c1a2++;
      } else if (d == 120) {
        cRafagas++;
      }
    }

    String frequentDurationLabel = '-';
    int maxCount = 0;
    if (cSegundos > maxCount) { maxCount = cSegundos; frequentDurationLabel = 'Segundos'; }
    if (cMenos1 > maxCount) { maxCount = cMenos1; frequentDurationLabel = '< 1 min'; }
    if (c1a2 > maxCount) { maxCount = c1a2; frequentDurationLabel = '1-2 min'; }
    if (cRafagas > maxCount) { maxCount = cRafagas; frequentDurationLabel = 'Ráfagas'; }

    final triggerMap = <String, int>{};
    for (var c in crises) {
      if (c.trigger.isNotEmpty) {
        triggerMap.update(c.trigger, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final topTriggers = triggerMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); 

    final dfFull = DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'es_CL');
    final dfShort = DateFormat('dd/MM/yyyy', 'es_CL');
    final tf = DateFormat.Hm('es_CL');

    String capitalize(String s) {
      if (s.isEmpty) return s;
      return s[0].toUpperCase() + s.substring(1);
    }

    pw.Widget buildInfoColumn(String label, String value) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: pdfTextSub)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfTextMain)),
        ],
      );
    }

    pw.Widget buildStatCard(String title, String value, String subtitle) {
      return pw.Container(
        width: 150, 
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdfAccent)),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          ],
        ),
      );
    }

    pw.Widget buildCompactRow(String label, String count, int total) {
      final pct = total > 0 ? (int.parse(count) / total * 100).round() : 0;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text('$count ($pct%)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    pw.Widget buildDetailBadge(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: pdfBgLight,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: pdfTextMain)),
          ],
        ),
      );
    }

    pw.Widget buildDetailRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$label ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: pdfTextMain)),
              pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
            ],
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Auna - Registro de Crisis Emocionales', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.Text('Documento confidencial - Solo para uso personal o médico', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ]
        ),
        build: (ctx) => [
          // 1. ENCABEZADO
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Auna', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: pdfAccent)),
                  pw.Text('Reporte Médico', style: pw.TextStyle(fontSize: 16, color: pdfTextMain)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Generado el:', style: pw.TextStyle(fontSize: 10, color: pdfTextSub)),
                  pw.Text(dfShort.format(DateTime.now()), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: pdfTextMain)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // 2. INFO PACIENTE
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: pdfBgLight,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                buildInfoColumn('Paciente', userName),
                buildInfoColumn('Período Analizado', '${dfShort.format(start)} - ${dfShort.format(end)}'),
                buildInfoColumn('Total Días', '${end.difference(start).inDays + 1} días'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // 3. RESUMEN
          pw.Text('Resumen del Período', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: pdfTextMain)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              buildStatCard('Total Crisis', '$totalCrisis', 'Eventos registrados'),
              buildStatCard('Intensidad Prom.', avgIntensity.toStringAsFixed(1), '/ 10 Escala'),
              buildStatCard('Duración Frecuente', frequentDurationLabel, 'Categoría más común'),
            ],
          ),
          pw.SizedBox(height: 24),

          // 4. ESTADÍSTICAS
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Distribución por Duración', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    buildCompactRow('Segundos', '$cSegundos', totalCrisis),
                    buildCompactRow('< 1 min', '$cMenos1', totalCrisis),
                    buildCompactRow('1-2 min', '$c1a2', totalCrisis),
                    buildCompactRow('Ráfagas', '$cRafagas', totalCrisis),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Desencadenantes Principales', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    if (topTriggers.isEmpty) pw.Text('No registrados', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ...topTriggers.take(3).map((e) => buildCompactRow(e.key, '${e.value}', totalCrisis)),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 20),

          // 5. LISTA DETALLADA
          pw.Text('Registro Detallado de Crisis', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: pdfTextMain)),
          pw.SizedBox(height: 12),

          ...List.generate(crises.length, (index) {
            final c = crises[index];
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(capitalize(dfFull.format(c.date)), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pdfAccent)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      buildDetailBadge('Hora', tf.format(c.date)),
                      pw.SizedBox(width: 12),
                      buildDetailBadge('Duración', durationToLabel(c.duration)),
                      pw.SizedBox(width: 12),
                      buildDetailBadge('Intensidad', '${c.intensity.toInt()}/10'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  if (c.trigger.isNotEmpty) buildDetailRow('Desencadenante:', c.trigger),
                  if (c.symptoms.isNotEmpty) buildDetailRow('Síntomas:', c.symptoms.join(', ')),
                  if (c.notes.isNotEmpty) buildDetailRow('Notas:', c.notes),
                ],
              ),
            );
          }),
        ],
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final name = "reporte_auna_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";
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
          SnackBar(content: Text('Error: $msg')),
        );
      }
    }
  }

  // BLE
  void _showAmuletoSheet() {
    final bleWatch = context.watch<BleManager>();
    final ble = context.read<BleManager>();
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
              ListTile(
                leading: Icon(
                  conectado ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                  color: Colors.white,
                ),
                title: Text(
                  conectado ? 'Conectado' : bleWatch.connectionStateLabel,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  conectado ? 'Recibiendo eventos del amuleto' : 'Toca para conectar',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: conectado ? null : ble.connect,
              ),
              if (conectado)
                ListTile(
                  leading: const Icon(Icons.link_off, color: Colors.white),
                  title: const Text('Desconectar', style: TextStyle(color: Colors.white)),
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

  // UI PRINCIPAL
  @override
  Widget build(BuildContext context) {
    // Escuchamos el proveedor
    final ble = context.watch<BleManager>();
    final userProvider = context.watch<UserProvider>(); 
    
    // Obtener datos del contacto
    final String? phone = userProvider.emergencyPhone;
    final String? name = userProvider.emergencyName;

    // Lógica para el subtítulo: "Nombre • Teléfono"
    String emergencySubtitle;
    if (phone != null && phone.isNotEmpty) {
      if (name != null && name.isNotEmpty) {
        emergencySubtitle = '$name • $phone';
      } else {
        emergencySubtitle = phone;
      }
    } else {
      emergencySubtitle = 'Configura un contacto para notificar';
    }

    final subtitleBle = ble.isConnected
        ? 'Conectado — recibiendo eventos'
        : (ble.connectionStateLabel.startsWith('Reconectando')
            ? ble.connectionStateLabel
            : (ble.connectionStateLabel == 'Desconectado'
                ? 'Conectar y configurar'
                : ble.connectionStateLabel));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/imagenes/fondo.JPG', fit: BoxFit.cover),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              child: Column(
                children: [
                  const Text('Configuración', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _navy)),
                  const SizedBox(height: 30),
                  _ActionCard(
                    icon: Icons.bluetooth,
                    title: 'Amuleto Bluetooth',
                    subtitle: subtitleBle,
                    onTap: _showAmuletoSheet,
                  ),
                  const SizedBox(height: 16),
                  
                  // --- TARJETA DE EMERGENCIA ---
                  _ActionCard(
                    icon: Icons.person_add_alt_1,
                    title: 'Contacto de Emergencia',
                    subtitle: emergencySubtitle,
                    onTap: _showContactDialog, 
                  ),
                  // -----------------------------
                  
                  const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}