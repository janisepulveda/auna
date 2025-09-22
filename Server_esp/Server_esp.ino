/*
    Adaptación para leer datos de sensor FSR y enviarlos a través de BLE.
*/

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// UUIDs del servicio y la característica
// Estos deben ser los mismos que en tu aplicación de Flutter
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// PIN y UMBRAL para el sensor FSR
// El pin del sensor de presión. Usa un pin analógico.
#define PIN_SENSOR          34 
// El valor de presión por encima del cual se considera una "crisis".
// Ajusta este valor en base a tus pruebas.
#define UMBRAL_PRESION      500 

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Callback para manejar eventos de conexión/desconexión
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
    }

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
    }
};

void setup() {
    Serial.begin(115200);
    Serial.println("Iniciando el servidor BLE de Auna...");

    // Inicializa el dispositivo BLE y le asigna el nombre "Auna"
    BLEDevice::init("Auna");

    // Crea el servidor y el servicio BLE
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService* pService = pServer->createService(SERVICE_UUID);
    
    // Crea la característica BLE para la lectura de datos
    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_READ |
                        BLECharacteristic::PROPERTY_NOTIFY | // Permite notificar cambios
                        BLECharacteristic::PROPERTY_WRITE 
                      );

    pService->start();

    // Inicia la publicidad del servicio BLE
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("Esperando que un cliente se conecte...");
}

void loop() {
    // Si la aplicación se conecta
    if (deviceConnected) {
        int valorSensor = analogRead(PIN_SENSOR); // Lee el valor del sensor
        int valorBinario = (valorSensor > UMBRAL_PRESION) ? 1 : 0; // Decide si es una crisis o no

        // Notifica el valor binario a la aplicación
        pCharacteristic->setValue(String(valorBinario).c_str());
        pCharacteristic->notify();

        delay(100); // Espera un corto tiempo para evitar notificaciones excesivas
    }
    
    // Maneja la reconexión si la aplicación se desconecta
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // Espera 500ms antes de reiniciar la publicidad
        pServer->startAdvertising();
        Serial.println("Iniciando publicidad de nuevo...");
        oldDeviceConnected = deviceConnected;
    }

    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }
}
