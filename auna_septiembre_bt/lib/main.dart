// material.dart: contiene los widgets de material design de flutter.
// flutter_reactive_ble.dart: la biblioteca que usaremos para la conectividad BLE.
// permission_handler.dart: para solicitar permisos de bluetooth y ubicación.
// dart:async: para manejar operaciones asíncronas y streams (flujos de datos).
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

// la función principal que se ejecuta al iniciar la aplicación.
void main() {
  runApp(const MyApp());
}

// MyApp es un widget StatelessWidget, lo que significa que no cambia.
// es la raíz de la aplicación y define la configuración básica.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor de Neuralgia',
      theme: ThemeData(
        // define el tema de la aplicación, como los colores.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // la página principal de la aplicación.
      home: const BluetoothConnectionScreen(),
    );
  }
}

// este es el widget principal que contiene toda la lógica de la UI.
// es un StatefulWidget porque su estado (conexión, status) va a cambiar.
class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({super.key});

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

// la clase State que maneja la lógica y el estado del widget.
class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  // instancia de la biblioteca BLE.
  final _ble = FlutterReactiveBle();

  // variables para el estado de la aplicación.
  // muestran el estado de la conexión en la UI.
  String _connectionStatus = 'Desconectado';
  String? _deviceId;  // El ID del dispositivo conectado, si existe.
  final String _esp32Name = 'Auna'; // Cambia esto al nombre de tu dispositivo BLE

  // variables para gestionar los "streams" (flujos de datos) de BLE.
  // es crucial para poder cancelar las operaciones (ej. detener escaneo).
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;

  // función asíncrona para solicitar los permisos necesarios.
  // en android, se requieren permisos de bluetooth y ubicación.
  Future<void> _requestPermissions(BuildContext context) async {
    // solicita los permisos de bluetooth y ubicación en Android
    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      if (status[Permission.bluetoothScan] != PermissionStatus.granted) {
        debugPrint('Permisos de Bluetooth no concedidos. Verifica la configuración.');
        setState(() {
          _connectionStatus = 'Permisos de Bluetooth no concedidos';
        });
        return;
      }
    }
  }

  // función para iniciar el proceso de conexión. se llama cuando se presiona el botón.
  void _startConnection() async {
    setState(() {
      _connectionStatus = 'Buscando dispositivo...';
    });
    debugPrint('Comenzando escaneo...');

    try {
      await _requestPermissions(context);
      _scanSubscription?.cancel(); // cancela cualquier escaneo previo.
      // inicia el escaneo de dispositivos BLE.
      _scanSubscription = _ble.scanForDevices(withServices: []).listen((device) {
        debugPrint('Dispositivo encontrado: ${device.name}, ID: ${device.id}');
        if (device.name == _esp32Name) {
          // si el nombre coincide, detiene el escaneo y se prepara para conectar.
          _scanSubscription?.cancel();
          setState(() {
            _connectionStatus = 'Dispositivo encontrado. Conectando...';
            _deviceId = device.id;
          });
          debugPrint('Conectando a $_esp32Name...');
          _connectToDevice(device.id);
        }
      }, onError: (e) {
        // manejo de errores durante el escaneo.
        debugPrint('Error de escaneo: $e');
        setState(() {
          _connectionStatus = 'Error de escaneo: $e';
        });
      });
      
      // detiene el escaneo después de 10 segundos si no encuentra el dispositivo.
      Future.delayed(const Duration(seconds: 10), () {
        if (_connectionStatus == 'Buscando dispositivo...') {
          _scanSubscription?.cancel();
          setState(() {
            _connectionStatus = 'No se encontró el dispositivo.';
          });
          debugPrint('Escaneo finalizado. No se encontró el dispositivo.');
        }
      });

    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');
      setState(() {
        _connectionStatus = 'Error al solicitar permisos: $e';
      });
    }
  }

  // función para conectarse a un dispositivo específico.
  void _connectToDevice(String deviceId) {
    // escucha los cambios en el estado de la conexión.
    _connectionSubscription = _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    ).listen((state) {
      debugPrint('Estado de conexión: ${state.connectionState}');
      if (state.connectionState == DeviceConnectionState.connected) {
        setState(() {
          _connectionStatus = 'Conectado a $_esp32Name';
        });
        debugPrint('Conexión exitosa.');
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        setState(() {
          _connectionStatus = 'Desconectado';
        });
        debugPrint('Dispositivo desconectado.');
      }
    }, onError: (e) {
      // manejo de errores durante la conexión.
      debugPrint('Error de conexión: $e');
      setState(() {
        _connectionStatus = 'Error de conexión: $e';
      });
    });
  }

  // función para desconectar el dispositivo.
  void _disconnect() async {
    if (_deviceId != null) {
      debugPrint('Desconectando...');
      setState(() {
        _connectionStatus = 'Desconectando...';
      });
      _connectionSubscription?.cancel();
    }
    _scanSubscription?.cancel();
  }

  // el método build es donde se construye la interfaz de usuario.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de Neuralgia'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // muestra el estado actual de la conexión.
            Text(_connectionStatus, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              // el evento onPressed cambia según el estado de la conexión.
              onPressed: _connectionStatus.contains('Conectado') ? _disconnect : _startConnection,
              // el texto del botón cambia según el estado.
              child: Text(_connectionStatus.contains('Conectado') ? 'Desconectar' : 'Conectar BLE'),
            ),
          ],
        ),
      ),
    );
  }
}
