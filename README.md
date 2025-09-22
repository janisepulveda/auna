# 🪷 AUNA

## 📖 Acerca de

**AUNA** es un proyecto de diseño y tecnología inspirado en la neuralgia del trigémino, una enfermedad crónica caracterizada por un dolor intenso pero invisible.  

El sistema combina un **amuleto portátil** con una **aplicación móvil** para registrar y visualizar experiencias de dolor.  
Con un **toque**, el amuleto permite registrar una crisis, indicando en la app:  

- Intensidad del dolor (escala de 1 a 10).  
- Duración en segundos.  
- Notas opcionales.  

La aplicación organiza esta información en un calendario y la traduce en un **espacio visual vivo**, inspirado en los jardines: su crecimiento continuo, sus ciclos de apertura y recogimiento, y su imperfección natural.  

## Stack tecnológico

Estamos usando:

- ESP32-C3 super mini 

<https://docs.espressif.com/projects/esp-idf/en/stable/esp32c3/get-started/index.html>

<https://es.aliexpress.com/item/1005007205044247.html>

- Resistencia de presión FSR

## Instalación para desarrollar

### Arduino IDE 2.0

Dentro de la IDE, ir a Boards Manager y agregar `esp32 by Espressif Systems`.

En la barra de búsqueda de puertos para subir, elegimos uno que dice `Nologo ESP32C3 Super Mini`, que es el que corresponde a la placa que estamos usando.

## Comentarios

Probamos los códigos de BluetoothSerial y arrojaron errores del estilo

```txt
#error Bluetooth is not enabled! Please run`make menuconfig`to and enable it
```

Esto nos lleva a creer que este chip en particular, en esta dev board, no tiene Bluetooth clásico, pero sí BLE.

## Licencia

MIT
