# 🪷 AUNA

## 📖 Acerca de

**AUNA** es un proyecto de diseño y tecnología inspirado en la neuralgia del trigémino, una enfermedad crónica caracterizada por un dolor intenso pero invisible.  

El sistema combina un **amuleto portátil** con una **aplicación móvil** para registrar y visualizar experiencias de dolor.  
Con un **toque**, el amuleto permite registrar una crisis, indicando en la app:  

- Intensidad del dolor (escala de 1 a 10).  
- Duración en segundos.  
- Notas opcionales.  

La aplicación organiza esta información en un calendario y la traduce en un **espacio visual vivo**, inspirado en los jardines: su crecimiento continuo, sus ciclos de apertura y recogimiento, y su imperfección natural.  

## 🛠️ Stack tecnológico

Estamos usando:  

- [ESP32-C3 Super Mini](https://es.aliexpress.com/item/1005007205044247.html)  
- [ESP-IDF / documentación oficial](https://docs.espressif.com/projects/esp-idf/en/stable/esp32c3/get-started/index.html)  
- [Arduino IDE 2.0](https://www.arduino.cc/en/software) para prototipado inicial.  
- [Flutter](https://flutter.dev/) para la app móvil.

Sensores y componentes en exploración:  
- Botón físico.  
- Sensor capacitivo (touch).  
- Resistencia de presión (FSR), usada en modo binario y para rangos de dolor.  
- Motor vibrador (feedback háptico).  

## ⚙️ Instalación para desarrollar

### 1️⃣ Configuración del ESP32-C3 (Firmware)

**Requisitos:**  
- Arduino IDE 2.0 o superior  
- Driver del ESP32-C3 Super Mini (si tu sistema lo requiere)  
- Cable USB para conectar la placa  

**Pasos:**  
1. Abrir **Arduino IDE**.  
2. Ir a **Archivo → Preferencias** y agregar esta URL en “Gestor de URLs Adicionales de Placas”:  
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. Abrir **Herramientas → Placa → Gestor de Placas**, buscar `esp32 by Espressif Systems` e instalar.  
4. Seleccionar la placa: **Nologo ESP32C3 Super Mini**  
- Herramientas → Placa → ESP32C3 Dev Module / Nologo ESP32C3 Super Mini  
5. Seleccionar el puerto correcto:  
- Herramientas → Puerto → `/dev/cu.usbserial…` (Mac/Linux) o equivalente en Windows  
6. Subir el código de ejemplo: [`/arduino/ble_server.ino`](arduino/ble_server.ino)  

> 🔹 Este código de ejemplo **le da el nombre `Auna` a la placa**, que será usado posteriormente por la app Flutter para conectarse automáticamente al dispositivo BLE.

> ⚠️ Nota: Esta placa soporta **BLE**, pero no Bluetooth clásico. Si aparece:
>
> ```txt
> #error Bluetooth is not enabled! Please run `make menuconfig` to enable it
> ```
>
> es normal, BLE sí funciona.

### 2️⃣ Configuración del entorno Flutter (App móvil)

**Requisitos:**  
- Flutter SDK ([flutter.dev](https://flutter.dev/docs/get-started/install))  
- Android Studio (para emulador o despliegue en Android)  
- Xcode si quieres compilar en iOS 
- Editor de código: VSCode o Android Studio recomendado  

**Pasos:**  
1. Instalar **Flutter SDK** y agregarlo al PATH.  
2. Verificar instalación:
```bash
flutter doctor
```
3. Abrir el proyecto:
```bash
cd ruta/al/proyecto/flutter
code .
```
4. Instalar dependencias:
```bash
flutter pub get
```
5. Conectar un dispositivo físico o iniciar un emulador.
6. Ejecutar la app:
```bash
flutter run
```
- La app buscará automáticamente el dispositivo BLE llamado `Auna` y se conectará.

## 🚀 Estado del proyecto
Actualmente en etapa de **prototipado**:  
- Servidor BLE básico en ESP32-C3 funcionando.  
- Conexión establecida desde Flutter (Android/iOS).  
- Próximos pasos: enviar valores reales de sensores (botón, capacitivo, FSR) en lugar de texto fijo.  
- Prototipos físicos en **impresión 3D** explorando distintos formatos: broche, collar y pulsera.  

## Comentarios

Probamos los códigos de BluetoothSerial y arrojaron errores del estilo

```txt
#error Bluetooth is not enabled! Please run`make menuconfig`to and enable it
```

Esto nos lleva a creer que este chip en particular, en esta dev board, no tiene Bluetooth clásico, pero sí BLE.

## Licencia

MIT
