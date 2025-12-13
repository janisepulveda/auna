/**
 * FIRMWARE FINAL - MODO HACK (Resistencia Interna)
 * Requisito: HABER CORTADO EL CABLE A TIERRA DEL SENSOR.
 */

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define PIN_SENSOR          3 

// Con resistencia interna, los valores suelen ser bien claros (0 o 4095).
// Ponemos 1000 para asegurar.
#define UMBRAL_PRESION      1000

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

unsigned long tiempoInicioPresion = 0; 
bool presionDetectada = false;       
bool notificacionEmergenciaEnviada = false; 

class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) { deviceConnected = true; Serial.println(">> CONECTADO <<"); }
    void onDisconnect(BLEServer* pServer) { deviceConnected = false; Serial.println(">> DESCONECTADO <<"); }
};

void setup() {
    Serial.begin(115200);
    Serial.println("--- MODO RESISTENCIA INTERNA (PULL-DOWN) ---");

    // ESTA ES LA CLAVE: El ESP32 pone su propia resistencia.
    pinMode(PIN_SENSOR, INPUT_PULLDOWN); 

    BLEDevice::init("Auna");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService* pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_NOTIFY 
                      );
    pService->start();
    BLEDevice::getAdvertising()->addServiceUUID(SERVICE_UUID);
    BLEDevice::startAdvertising();
    
    Serial.println("Listo. Al presionar deberías ver valores altos.");
}

void loop() {
    int valorSensor = analogRead(PIN_SENSOR);

    // DEBUG: Solo para que veas que revivió
    if (valorSensor > 100) {
        Serial.print("Lectura: ");
        Serial.println(valorSensor);
    }

    // LÓGICA DE CRISIS/EMERGENCIA
    if (valorSensor > UMBRAL_PRESION) {
        if (!presionDetectada) {
            presionDetectada = true;
            tiempoInicioPresion = millis();
            notificacionEmergenciaEnviada = false;
            Serial.println("-> Presionando...");
        } else {
            // 3 Segundos -> EMERGENCIA
            if (!notificacionEmergenciaEnviada && (millis() - tiempoInicioPresion >= 3000)) {
                Serial.println("!!! EMERGENCIA !!!");
                if (deviceConnected) {
                    pCharacteristic->setValue("EMERGENCIA");
                    pCharacteristic->notify();
                }
                notificacionEmergenciaEnviada = true;
            }
        }
    } else {
        if (presionDetectada) {
            // Soltó -> CRISIS
            if (millis() - tiempoInicioPresion >= 200 && !notificacionEmergenciaEnviada) {
                Serial.println(">>> CRISIS ENVIADA <<<");
                if (deviceConnected) {
                    pCharacteristic->setValue("CRISIS");
                    pCharacteristic->notify();
                }
            }
            presionDetectada = false;
            notificacionEmergenciaEnviada = false;
        }
    }
    
    // Reconexión
    if (!deviceConnected && oldDeviceConnected) { delay(500); pServer->startAdvertising(); oldDeviceConnected = deviceConnected; }
    if (deviceConnected && !oldDeviceConnected) { oldDeviceConnected = deviceConnected; }
    
    delay(1000);
}