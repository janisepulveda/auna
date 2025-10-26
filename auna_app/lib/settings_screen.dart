// lib/settings_screen.dart

// --- IMPORTS COMPLETOS Y VERIFICADOS ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart'; // Asegúrate que este archivo exista y tenga CrisisModel
// Imports para PDF y archivos
import 'dart:io';            // Para File y Platform
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Usamos alias 'pw'
import 'package:path_provider/path_provider.dart'; // Para directorios
import 'package:open_file_plus/open_file_plus.dart'; // Para abrir PDF
import 'package:intl/intl.dart';                      // Para formatear fechas
// Imports para BLE
import 'dart:async';         // Para StreamSubscription
import 'dart:convert';       // Para utf8
import 'dart:math';          // Para 'max'
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart'; // Para BLE
import 'package:permission_handler/permission_handler.dart';    // Para permisos
import 'package:shared_preferences/shared_preferences.dart';      // Para guardar calibración

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- Lógica BLE ---
  final _ble = FlutterReactiveBle();
  String _estadoConexion = 'Desconectado';
  final String _nombreEsp32 = 'Auna'; // Nombre exacto del dispositivo BLE
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
    // Escucha cambios globales en dispositivos conectados/desconectados
    _ble.connectedDeviceStream.listen((update) {
       if(!mounted) return; // Evita error si el widget se desmonta rápido
       if(update.connectionState == DeviceConnectionState.connected){
         setState(() {
           _estadoConexion = 'Conectado';
           _connectedDeviceId = update.deviceId;
           _leerDatos(update.deviceId); // Inicia lectura al conectar
         });
       } else if (update.connectionState == DeviceConnectionState.disconnected) {
         // Si el dispositivo desconectado es el nuestro, actualiza estado
         if(update.deviceId == _connectedDeviceId) {
           setState(() {
             _estadoConexion = 'Desconectado';
             _connectedDeviceId = null;
             _suscripcionDatos?.cancel(); // Detiene lectura al desconectar
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

  // Carga el valor máximo guardado
  void _cargarValorMaximo() async {
     try {
       final prefs = await SharedPreferences.getInstance();
       if(mounted) {
          setState(() {
            _valorMaximoDolor = prefs.getInt('valorMaximoDolor') ?? 0;
          });
       }
     } catch (e) {
       debugPrint("Error cargando valor máximo: $e");
     }
  }

  // Guarda el valor máximo
   void _guardarValorMaximo(int valor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('valorMaximoDolor', valor);
    } catch (e) {
      debugPrint("Error guardando valor máximo: $e");
    }
  }

  // Solicita permisos necesarios
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

  // Inicia la búsqueda BLE
  void _iniciarConexion() async {
    await _suscripcionEscaneo?.cancel(); await _suscripcionConexion?.cancel(); await _suscripcionDatos?.cancel();
    _suscripcionEscaneo = null; _suscripcionConexion = null; _suscripcionDatos = null;
    if(!mounted) return;
    setState(() { _estadoConexion = 'Buscando...'; _connectedDeviceId = null; });
    bool permissionsGranted = await _solicitarPermisos();
    if (!permissionsGranted) { if(mounted) setState(() => _estadoConexion = 'Permisos denegados'); return; }

    _suscripcionEscaneo = _ble.scanForDevices(withServices: [_uuidServicio]).listen((device) {
      debugPrint('Encontrado: ${device.name}, ID: ${device.id}');
      if (device.name == _nombreEsp32) {
        _suscripcionEscaneo?.cancel();
        if(mounted) setState(() => _estadoConexion = 'Conectando...');
        _conectarDispositivo(device.id);
      }
    }, onError: (e) {
      debugPrint('Error scan: $e'); if (mounted) setState(() => _estadoConexion = 'Error escaneo');
    });

    Future.delayed(const Duration(seconds: 15), () {
      if (_estadoConexion == 'Buscando...' && mounted) {
        _suscripcionEscaneo?.cancel(); setState(() => _estadoConexion = 'No encontrado');
      }
    });
  }

  // Conecta al dispositivo BLE
  void _conectarDispositivo(String deviceId) {
    _suscripcionConexion = _ble.connectToDevice(
      id: deviceId, connectionTimeout: const Duration(seconds: 20),
    ).listen(
      (update) {
        if (update.connectionState == DeviceConnectionState.connected) {
           _connectedDeviceId = deviceId; _leerDatos(deviceId);
        }
     },
     onError: (e) {
       debugPrint('Error conexión $deviceId: $e');
       if (mounted) setState(() => _estadoConexion = 'Error conexión');
     }
    );
  }

  // Se suscribe a la característica BLE para recibir datos
  void _leerDatos(String deviceId) {
    final characteristic = QualifiedCharacteristic(
      serviceId: _uuidServicio, characteristicId: _uuidCaracteristica, deviceId: deviceId,
    );
    _suscripcionDatos?.cancel();
    _suscripcionDatos = _ble.subscribeToCharacteristic(characteristic).listen((data) {
      if (_estaCalibrando && mounted) {
        try {
          String datosSensor = utf8.decode(data);
          int? valorCrudo = int.tryParse(datosSensor);
          if (valorCrudo != null) {
            _valoresCalibracion.add(valorCrudo);
            // ¡Llamamos a setState aquí para que la UI se actualice!
            setState(() {});
            debugPrint('Dato cal: $valorCrudo');
          } else { debugPrint('Dato BLE no entero: $datosSensor'); }
        } catch (e) { debugPrint('Error decode BLE: $e. Dato(bytes): $data'); }
      }
    }, onError: (e) {
      debugPrint('Error al leer datos: $e'); if (mounted) setState(() => _estadoConexion = 'Error lectura');
    });
  }

  // Inicia la UI de calibración (CORREGIDO para error 'use_of_void_result')
  void _iniciarCalibracion() {
    if (_estadoConexion != 'Conectado') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero conecta el amuleto.')));
      return;
    }
    // Reinicia calibración
    setState(() {
      _estaCalibrando = true;
      _valoresCalibracion = [];
    });

    // Timer para finalizar automáticamente
    Timer? calibrationTimer = Timer(const Duration(seconds: 5), () {
        // Asegura que solo finalice si aún está calibrando y el widget existe
        if (_estaCalibrando && mounted) {
           _finalizarCalibracion(isManual: false);
         }
    });

    showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar tocando fuera
      builder: (dialogContext) {
        // Usamos StatefulBuilder para que el contenido del diálogo se actualice
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            // El setState general en _leerDatos se encargará de actualizar esto
            // Ya no necesitamos escuchar onData aquí dentro

            return AlertDialog(
              title: const Text("Calibrando..."),
              // Mostramos el conteo actual directamente
              content: Text("Presiona el amuleto con fuerza máxima (5 seg).\nLecturas: ${_valoresCalibracion.length}"),
              actions: [
                TextButton(
                  onPressed: () {
                    calibrationTimer.cancel(); // Cancela el timer si se finaliza manualmente
                    _finalizarCalibracion(isManual: true); // Indica que fue manual
                  },
                  child: const Text("Finalizar Ahora")
                )
              ],
            );
          }
        );
      },
    ).then((_) {
       // Limpieza final cuando el diálogo se cierra
       calibrationTimer.cancel(); // Asegura cancelar el timer
       // Si por alguna razón sigue calibrando (ej. error), lo detenemos
       if (_estaCalibrando && mounted) {
          setState(() => _estaCalibrando = false);
       }
    });
  }


 // Finaliza la calibración
 void _finalizarCalibracion({bool isManual = false}) {
    // Si no fue manual y el diálogo aún existe, ciérralo
    if (!isManual && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!_estaCalibrando || !mounted) return;
    setState(() => _estaCalibrando = false);
    if (_valoresCalibracion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calibración cancelada: No se recibieron datos.'))); return;
    }
    try {
      int presionMaxima = _valoresCalibracion.reduce(max);
      setState(() => _valorMaximoDolor = presionMaxima);
      _guardarValorMaximo(_valorMaximoDolor);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calibración completada. Valor máximo: $presionMaxima')));
    } catch (e) {
       debugPrint("Error al calcular max: $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al procesar datos.')));
    }
  }

  // Desconecta del dispositivo BLE
  void _desconectar() async {
    await _suscripcionDatos?.cancel();
    await _suscripcionConexion?.cancel();
    _suscripcionDatos = null; _suscripcionConexion = null;
    if (mounted) { setState(() { _estadoConexion = 'Desconectado'; _connectedDeviceId = null; }); }
    debugPrint("Desconexión finalizada.");
  }
  // --- Fin Lógica BLE ---


  // --- Lógica PDF ---
  Future<void> _exportHistoryToPdf() async {
    final pdf = pw.Document();
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final crises = userProvider.registeredCrises.toList();
    final userName = userProvider.user?.name ?? 'Usuario Auna';

    if (crises.isEmpty) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay crisis registradas.'))); return; }
    crises.sort((a, b) => a.date.compareTo(b.date));
    final DateFormat dateFormatter = DateFormat.yMMMMd('es_CL');
    final DateFormat timeFormatter = DateFormat.Hm();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Reporte de Crisis - $userName', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
          pw.Paragraph(text: 'Generado el: ${DateFormat.yMMMMd('es_CL').add_Hm().format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray( // Usamos TableHelper
            headers: ['Fecha', 'Hora', 'Intensidad', 'Duración (min)', 'Notas'],
            data: crises.map((crisis) => [
              dateFormatter.format(crisis.date), timeFormatter.format(crisis.date),
              crisis.intensity.toInt().toString(), crisis.duration.toString(),
              crisis.notes.isNotEmpty ? crisis.notes : '-',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            cellAlignment: pw.Alignment.centerLeft, cellStyle: const pw.TextStyle(fontSize: 10),
            columnWidths: { 0: const pw.FixedColumnWidth(75), 1: const pw.FixedColumnWidth(40), 2: const pw.FixedColumnWidth(55), 3: const pw.FixedColumnWidth(65), 4: const pw.IntrinsicColumnWidth(), },
            border: pw.TableBorder.all(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    try {
      final Directory output = await getApplicationDocumentsDirectory();
      final String fileName = "historial_auna_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";
      final String filePath = "${output.path}/$fileName";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      debugPrint("PDF guardado en: ${file.path}");
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
          debugPrint("No se pudo abrir PDF: ${result.message}");
          if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(SnackBar( content: Text('PDF guardado en Documentos ($fileName)'), duration: const Duration(seconds: 5), ));
      }
    } catch (e) {
      debugPrint("Error PDF: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exportando PDF: ${e.toString().substring(0, min(e.toString().length, 100))}')));
    }
  }
  // --- FIN LÓGICA PDF ---

  @override
  Widget build(BuildContext context) {
    bool estaConectado = _estadoConexion == 'Conectado';
    return Scaffold(
      appBar: AppBar(
        title: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final userName = userProvider.user?.name ?? 'Usuario';
              final userEmail = userProvider.user?.email ?? 'sin-email@auna.app';
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
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsCard(
            icon: Icons.bluetooth, title: 'Conectar Amuleto',
            subtitle: 'Estado: $_estadoConexion',
            trailing: estaConectado
              ? TextButton(onPressed: _desconectar, child: const Text('Desconectar'))
              : ElevatedButton(
                  onPressed: (_estadoConexion == 'Buscando...' || _estadoConexion == 'Conectando...') ? null : _iniciarConexion,
                  child: Text(
                    _estadoConexion == 'Desconectado' || _estadoConexion == 'No encontrado' || _estadoConexion.startsWith('Error') || _estadoConexion == 'Permisos denegados'
                    ? 'Buscar Amuleto' : _estadoConexion
                  )
                ),
          ),
          if (estaConectado)
            _buildSettingsCard(
              icon: Icons.tune, title: 'Calibración del Sensor',
              subtitle: _valorMaximoDolor == 0 ? 'Realiza la calibración inicial' : 'Calibrado. Máx: $_valorMaximoDolor',
              trailing: TextButton(
                onPressed: _estaCalibrando ? null : _iniciarCalibracion,
                child: Text(_valorMaximoDolor == 0 ? 'Iniciar Calibración' : 'Recalibrar'),
              ),
            ),
          _buildSettingsCard(
            icon: Icons.person_add_alt_1, title: 'Contacto de Emergencia',
            subtitle: 'Configura un contacto para notificar',
            trailing: const Icon(Icons.chevron_right), onTap: (){
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función no implementada')));
             },
          ),
          _buildSettingsCard(
            icon: Icons.download, title: 'Exportar Historial',
            subtitle: 'Descarga tus datos en formato PDF',
            trailing: const Icon(Icons.download_done),
            onTap: _exportHistoryToPdf,
          ),
        ],
      ),
    );
  }

  // Widget _buildSettingsCard (sin cambios)
  Widget _buildSettingsCard({
    required IconData icon, required String title,
    required String subtitle, required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2, margin: const EdgeInsets.symmetric(vertical: 8),
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
} // Fin de la clase _SettingsScreenState