//Adaptación para leer datos de sensor FSR y enviarlos a través de BLE.

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// UUIDs del servicio y la característica.
// estos deben ser los mismos que en tu aplicación de flutter.
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// PIN del sensor FSR.
// el pin del sensor de presión. Usa un pin analógico.
#define PIN_SENSOR          4 

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// callback para manejar eventos de conexión/desconexión
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

    // inicializa el dispositivo BLE y le asigna el nombre "Auna".
    BLEDevice::init("Auna");

    // crea el servidor y el servicio BLE.
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService* pService = pServer->createService(SERVICE_UUID);
    
    // crea la característica BLE para la lectura de datos.
    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_READ |
                        BLECharacteristic::PROPERTY_NOTIFY | // Permite notificar cambios
                        BLECharacteristic::PROPERTY_WRITE 
                      );

    pService->start();

    // inicia la publicidad del servicio BLE.
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("Esperando que un cliente se conecte...");
}

void loop() {
    // i la aplicación se conecta. lee el valor crudo del sensor.
    if (deviceConnected) {
        int valorSensor = analogRead(PIN_SENSOR);
        
        // notifica el valor del nivel de dolor a la aplicación.
        pCharacteristic->setValue(String(valorSensor).c_str());
        pCharacteristic->notify();

        // espera un corto tiempo para evitar notificaciones excesivas.
        delay(100); 
    }
    
    // maneja la reconexión si la aplicación se desconecta.
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); 
        pServer->startAdvertising();
        Serial.println("Iniciando publicidad de nuevo...");
        oldDeviceConnected = deviceConnected;
    }

    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }
}
