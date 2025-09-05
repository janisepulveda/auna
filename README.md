# auna

## Acerca de

Proyecto por @janisepulveda.

## Stack tecnológico

Estamos usando:

- ESP32-C3

<https://docs.espressif.com/projects/esp-idf/en/stable/esp32c3/get-started/index.html>

<https://es.aliexpress.com/item/1005007205044247.html>

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
