// material.dart: contiene los widgets básicos para la interfaz de flutter.
// flutter_reactive_ble.dart: la biblioteca que nos permite comunicarnos con el bluetooth.
// permission_handler.dart: para solicitar permisos de bluetooth y ubicación al usuario.
// dart:async: para manejar operaciones asíncronas y streams (flujos de datos).
// dart:convert: para codificar y decodificar datos.
// dart:io: para trabajar con archivos y plataformas.
// dart:math: para operaciones matemáticas, como encontrar el valor máximo.
// shared_preferences: para guardar la calibración del usuario localmente.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// la función principal que se ejecuta al iniciar la aplicación.
void main() {
  runApp(const MyApp());
}

// MyApp es un widget StatelessWidget, lo que significa que su estado no cambia.
// es la raíz de la aplicación y define la configuración básica, como el título y el tema.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor de Neuralgia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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

// la clase State maneja la lógica y el estado del widget.
class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  final _ble = FlutterReactiveBle();

  String _estadoConexion = 'Desconectado';
  final String _nombreEsp32 = 'Auna';
  int _nivelDolor = 0;
  bool _esCrisis = false;
  int _valorMaximoDolor = 0;
  bool _estaCalibrando = false;
  List<int> _valoresCalibracion = [];
  
  // UUID del servicio y característica para la comunicación con la ESP32
  // estos deben coincidir con los valores en el código de tu Arduino IDE
  final String _uuidServicio = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String _uuidCaracteristica = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // variables para gestionar los "streams" (flujos de datos) de BLE.
  // es crucial para poder cancelar las operaciones (ej. detener escaneo).
  StreamSubscription? _suscripcionEscaneo;
  StreamSubscription? _suscripcionConexion;
  StreamSubscription? _suscripcionDatos;

  // se llama cuando el widget se inicializa.
  // carga el valor máximo de presión guardado en el teléfono.
  @override
  void initState() {
    super.initState();
    _cargarValorMaximo();
  }

  // carga el valor máximo de dolor guardado localmente usando SharedPreferences.
  void _cargarValorMaximo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _valorMaximoDolor = prefs.getInt('valorMaximoDolor') ?? 0;
    });
  }

  // guarda el valor máximo de dolor
  void _guardarValorMaximo(int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('valorMaximoDolor', valor);
  }

  // función asíncrona para solicitar los permisos necesarios.
  // en android, se requieren permisos de bluetooth y ubicación.
  Future<void> _solicitarPermisos() async {
    if (Platform.isAndroid) {
      final status = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      if (status[Permission.bluetoothScan] != PermissionStatus.granted) {
        debugPrint('Permisos de Bluetooth no concedidos. Verifica la configuración.');
        setState(() {
          _estadoConexion = 'Permisos de Bluetooth no concedidos';
        });
      }
    }
  }

  // función para iniciar el proceso de conexión. se llama cuando se presiona el botón.
  void _iniciarConexion() async {
    // cancela cualquier operación de BLE previa para evitar errores.
    _suscripcionEscaneo?.cancel();
    _suscripcionConexion?.cancel();
    _suscripcionDatos?.cancel();
    
    setState(() {
      _estadoConexion = 'Buscando dispositivo...';
    });
    debugPrint('Comenzando escaneo...');

    try {
      await _solicitarPermisos();
      _suscripcionEscaneo = _ble.scanForDevices(withServices: []).listen((device) {
        debugPrint('Dispositivo encontrado: ${device.name}, ID: ${device.id}');
        if (device.name == _nombreEsp32) {
          // si el nombre coincide, detiene el escaneo y se prepara para conectar.
          _suscripcionEscaneo?.cancel();
          setState(() {
            _estadoConexion = 'Dispositivo encontrado. Conectando...';
          });
          debugPrint('Conectando a $_nombreEsp32...');
          _conectarDispositivo(device.id);
        }
      }, onError: (e) {
        // manejo de errores durante el escaneo.
        debugPrint('Error de escaneo: $e');
        setState(() {
          _estadoConexion = 'Error de escaneo: $e';
        });
      });
      
      // detiene el escaneo después de 10 segundos si no encuentra el dispositivo.
      Future.delayed(const Duration(seconds: 10), () {
        if (_estadoConexion == 'Buscando dispositivo...') {
          _suscripcionEscaneo?.cancel();
          setState(() {
            _estadoConexion = 'No se encontró el dispositivo.';
          });
          debugPrint('Escaneo finalizado. No se encontró el dispositivo.');
        }
      });

    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');
      setState(() {
        _estadoConexion = 'Error al solicitar permisos: $e';
      });
    }
  }

  // función para conectarse a un dispositivo específico.
  void _conectarDispositivo(String idDispositivo) {
    _suscripcionConexion = _ble.connectToDevice(
      id: idDispositivo,
      connectionTimeout: const Duration(seconds: 10),
    ).listen((state) {
      debugPrint('Estado de conexión: ${state.connectionState}');
      if (state.connectionState == DeviceConnectionState.connected) {
        setState(() {
          _estadoConexion = 'Conectado a $_nombreEsp32';
        });
        debugPrint('Conexión exitosa.');
        _leerDatos(idDispositivo);
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        setState(() {
          _estadoConexion = 'Desconectado';
        });
        debugPrint('Dispositivo desconectado.');
        _suscripcionDatos?.cancel();
      }
    }, onError: (e) {
      debugPrint('Error de conexión: $e');
      setState(() {
        _estadoConexion = 'Error de conexión: $e';
      });
    });
  }
  
  // función para leer datos del sensor
  void _leerDatos(String idDispositivo) {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(_uuidServicio),
      characteristicId: Uuid.parse(_uuidCaracteristica),
      deviceId: idDispositivo,
    );
    
    // nos suscribimos a los datos que envía la ESP32
    _suscripcionDatos = _ble.subscribeToCharacteristic(characteristic).listen((data) {
      String datosSensor = utf8.decode(data);
      int? valorCrudo = int.tryParse(datosSensor);
      
      if (valorCrudo != null) {
        debugPrint('Datos recibidos: $valorCrudo');
        // aquí se decide si se está calibrando o si se está monitoreando
        if (_estaCalibrando) {
          _valoresCalibracion.add(valorCrudo);
        } else {
          _calcularNivelDolor(valorCrudo);
        }
      }
    }, onError: (e) {
      debugPrint('Error de lectura: $e');
    });
  }

  // comienza el proceso de calibración, activando el modo de calibración.
  void _iniciarCalibracion() {
    setState(() {
      _estaCalibrando = true;
      _valoresCalibracion = [];
      _estadoConexion = 'Calibrando...';
    });
    debugPrint('Comenzando calibración. Presiona el sensor con tu fuerza máxima.');
  }

  // finaliza la calibración, calcula el valor máximo y lo guarda.
  void _finalizarCalibracion() {
    if (_valoresCalibracion.isEmpty) {
      setState(() {
        _estaCalibrando = false;
        _estadoConexion = 'Calibración cancelada. No se registraron datos.';
      });
      return;
    }
    // encuentra el valor máximo de todas las lecturas capturadas
    int presionMaxima = _valoresCalibracion.reduce(max);
    setState(() {
      _valorMaximoDolor = presionMaxima;
      _estaCalibrando = false;
      _estadoConexion = 'Conectado a $_nombreEsp32';
    });
    // guarda el valor máximo para que la calibración no sea necesaria la próxima vez.
    _guardarValorMaximo(_valorMaximoDolor);
    debugPrint('Calibración completada. Valor máximo registrado: $_valorMaximoDolor');
  }

  // mapea la lectura del sensor a una escala de 0 a 10 usando el valor de calibración.
  void _calcularNivelDolor(int valorCrudo) {
    if (_valorMaximoDolor == 0) {
      setState(() {
        _nivelDolor = 0;
        _esCrisis = false;
      });
      return;
    }

    // mapea el valor crudo a una escala del 0 al 10, usando el valor máximo de presión como referencia.
    int nivelCalculado = (valorCrudo * 10) ~/ _valorMaximoDolor;
    
    // asegura que el valor no sea menor a 0 o mayor a 10
    nivelCalculado = max(0, min(10, nivelCalculado));
    
    setState(() {
      _nivelDolor = nivelCalculado;
      _esCrisis = nivelCalculado > 0;
    });
  }

  // función para desconectar el dispositivo.
  void _desconectar() async {
    _suscripcionEscaneo?.cancel();
    _suscripcionConexion?.cancel();
    _suscripcionDatos?.cancel();
    setState(() {
      _estadoConexion = 'Desconectado';
      _esCrisis = false;
      _nivelDolor = 0;
    });
    debugPrint('Desconexión manual.');
  }

  // se llama cuando el widget se elimina. cierra todas las suscripciones de streams.
  @override
  void dispose() {
    _suscripcionEscaneo?.cancel();
    _suscripcionConexion?.cancel();
    _suscripcionDatos?.cancel();
    super.dispose();
  }

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
            Text(_estadoConexion, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            if (_estadoConexion.contains('Conectado'))
              Column(
                children: [
                  if (_estaCalibrando) ...[
                    const Text('Presiona el amuleto con tu fuerza máxima.', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 10),
                    // muestra el número de lecturas capturadas durante la calibración
                    Text('Lecturas capturadas: ${_valoresCalibracion.length}'),
                    const SizedBox(height: 20),
                    // Botón para terminar la calibración
                    ElevatedButton(
                      onPressed: _finalizarCalibracion,
                      child: const Text('Terminar Calibración'),
                    ),
                  ]
                  // si no hay valor de calibración, muestra el botón para iniciarla
                  else if (_valorMaximoDolor == 0) ...[
                    const Text('Inicia la calibración para comenzar', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _iniciarCalibracion,
                      child: const Text('Iniciar Calibración'),
                    ),
                  ]
                  // si ya está calibrado, muestra el estado de la crisis y el nivel de dolor
                  else ...[
                    Text(
                      _esCrisis ? '¡Crisis detectada!' : 'Sin crisis',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _esCrisis ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nivel de dolor: $_nivelDolor/10',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _valorMaximoDolor = 0;
                        _guardarValorMaximo(0);
                        setState(() {});
                        debugPrint('Calibración reiniciada.');
                      },
                      child: const Text('Reiniciar Calibración'),
                    ),
                  ]
                ],
              )
            // muestra un mensaje si no está conectado
            else
              const Text('Inicia la conexión para ver el estado'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _estadoConexion.contains('Conectado') && !_estaCalibrando ? _desconectar : _iniciarConexion,
              child: Text(_estadoConexion.contains('Conectado') ? 'Desconectar' : 'Conectar BLE'),
            ),
          ],
        ),
      ),
    );
  }
}
