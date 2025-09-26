// settings_screen.dart
import 'package:flutter/material.dart';
// Importa las librerías
import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  
  final _ble = FlutterReactiveBle();

  String _estadoConexion = 'Desconectado';
  final String _nombreEsp32 = 'Auna';
  bool _estaCalibrando = false;
  List<int> _valoresCalibracion = [];
  int _valorMaximoDolor = 0;
  
  final String _uuidServicio = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String _uuidCaracteristica = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  StreamSubscription? _suscripcionEscaneo;
  StreamSubscription? _suscripcionConexion;
  StreamSubscription? _suscripcionDatos;

  @override
  void initState() {
    super.initState();
    _cargarValorMaximo();
  }

  void _cargarValorMaximo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _valorMaximoDolor = prefs.getInt('valorMaximoDolor') ?? 0;
    });
  }

  void _guardarValorMaximo(int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('valorMaximoDolor', valor);
  }

  Future<void> _solicitarPermisos() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    }
  }

  void _iniciarConexion() async {
    _suscripcionEscaneo?.cancel();
    _suscripcionConexion?.cancel();
    _suscripcionDatos?.cancel();
    
    setState(() => _estadoConexion = 'Buscando...');
    await _solicitarPermisos();
    
    _suscripcionEscaneo = _ble.scanForDevices(withServices: []).listen((device) {
      if (device.name == _nombreEsp32) {
        _suscripcionEscaneo?.cancel();
        setState(() => _estadoConexion = 'Conectando...');
        _conectarDispositivo(device.id);
      }
    }, onError: (e) {
      setState(() => _estadoConexion = 'Error de escaneo');
    });
      
    Future.delayed(const Duration(seconds: 10), () {
      if (_estadoConexion == 'Buscando...') {
        _suscripcionEscaneo?.cancel();
        setState(() => _estadoConexion = 'No se encontró');
      }
    });
  }

  void _conectarDispositivo(String idDispositivo) {
    _suscripcionConexion = _ble.connectToDevice(
      id: idDispositivo,
    ).listen((state) {
      if (state.connectionState == DeviceConnectionState.connected) {
        setState(() => _estadoConexion = 'Conectado');
        _leerDatos(idDispositivo);
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        setState(() => _estadoConexion = 'Desconectado');
        _suscripcionDatos?.cancel();
      }
    }, onError: (e) {
      setState(() => _estadoConexion = 'Error de conexión');
    });
  }
  
  void _leerDatos(String idDispositivo) {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(_uuidServicio),
      characteristicId: Uuid.parse(_uuidCaracteristica),
      deviceId: idDispositivo,
    );
    
    _suscripcionDatos = _ble.subscribeToCharacteristic(characteristic).listen((data) {
      String datosSensor = utf8.decode(data);
      int? valorCrudo = int.tryParse(datosSensor);
      
      if (valorCrudo != null && _estaCalibrando) {
        _valoresCalibracion.add(valorCrudo);
        // Damos feedback visual de que se están recibiendo datos
        setState((){});
      }
    });
  }

  void _iniciarCalibracion() {
    setState(() {
      _estaCalibrando = true;
      _valoresCalibracion = [];
    });
    // Muestra un diálogo al usuario con instrucciones
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Iniciando Calibración"),
        content: Text("Presiona el amuleto con tu fuerza máxima durante unos segundos.\n\nLecturas capturadas: ${_valoresCalibracion.length}"),
        actions: [
          TextButton(
            onPressed: _finalizarCalibracion,
            child: const Text("Finalizar"),
          )
        ],
      ),
    );
  }

  void _finalizarCalibracion() {
    Navigator.of(context).pop(); // Cierra el diálogo
    if (_valoresCalibracion.isEmpty) {
      setState(() => _estaCalibrando = false);
      return;
    }
    int presionMaxima = _valoresCalibracion.reduce(max);
    setState(() {
      _valorMaximoDolor = presionMaxima;
      _estaCalibrando = false;
    });
    _guardarValorMaximo(_valorMaximoDolor);
  }
  
  void _desconectar() async {
    _suscripcionConexion?.cancel();
    // La desconexión se manejará automáticamente por el stream de conexión
  }

  @override
  void dispose() {
    _suscripcionEscaneo?.cancel();
    _suscripcionConexion?.cancel();
    _suscripcionDatos?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool estaConectado = _estadoConexion == 'Conectado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Pérez'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Text('ana.perez@gmail.com', style: TextStyle(color: Colors.grey[600])),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tarjeta para la conexión Bluetooth
          _buildSettingsCard(
            context: context,
            icon: Icons.bluetooth,
            title: 'Conectar Amuleto',
            subtitle: 'Gestiona la conexión Bluetooth',
            trailing: estaConectado
              ? TextButton(onPressed: _desconectar, child: const Text('Desconectar'))
              : ElevatedButton(onPressed: _iniciarConexion, child: Text(_estadoConexion)),
          ),
          
          if (estaConectado)
          _buildSettingsCard(
            context: context,
            icon: Icons.tune,
            title: 'Calibración del Sensor',
            subtitle: _valorMaximoDolor == 0
                ? 'Realiza la calibración inicial'
                : 'Calibrado. Valor máximo: $_valorMaximoDolor',
            trailing: TextButton(
              onPressed: _iniciarCalibracion,
              child: Text(_valorMaximoDolor == 0 ? 'Calibrar' : 'Recalibrar'),
            ),
          ),
          
          // Otros elementos de configuración del video
          _buildSettingsCard(
            context: context,
            icon: Icons.person_add_alt_1,
            title: 'Contacto de Emergencia',
            subtitle: 'Configura un contacto para notificar',
            trailing: const Icon(Icons.chevron_right),
            onTap: (){},
          ),
          _buildSettingsCard(
            context: context,
            icon: Icons.download,
            title: 'Exportar Historial',
            subtitle: 'Descarga tus datos en formato PDF',
            trailing: const Icon(Icons.chevron_right),
            onTap: (){},
          ),
        ],
      ),
    );
  }

  // Widget reutilizable para crear las tarjetas de opciones
  Widget _buildSettingsCard({
    required BuildContext context,
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