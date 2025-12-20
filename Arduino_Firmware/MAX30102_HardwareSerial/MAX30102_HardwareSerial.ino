#include <Wire.h>
#include "MAX30105.h"

// Pin Tanımları
const int LED_BLE = 8;   
const int LED_READY = 9; 
const int LED_MEAS = 10;  

MAX30105 sensor;

// Sistem Durumları
bool bleConnected = false;
bool isMeasuring = false;

// Zamanlayıcılar
unsigned long lastBlinkBLE = 0;
unsigned long lastBlinkMeas = 0;

// Seri Haberleşme Buffer
const byte numChars = 32;
char receivedChars[numChars];
boolean newData = false;

void setup() {
  pinMode(LED_BLE, OUTPUT);
  pinMode(LED_READY, OUTPUT);
  pinMode(LED_MEAS, OUTPUT);

  // Başlangıçta tüm LED'ler kapalı
  digitalWrite(LED_BLE, LOW);
  digitalWrite(LED_READY, LOW);
  digitalWrite(LED_MEAS, LOW);

  Serial.begin(9600);
  Wire.begin();
  Wire.setClock(400000); // I2C Hızını artır (Veri akışı rahatlar)

  if (!sensor.begin(Wire, I2C_SPEED_FAST)) {
    while (1) {
      digitalWrite(LED_BLE, HIGH);
      digitalWrite(LED_READY, HIGH);
      delay(200);
      digitalWrite(LED_BLE, LOW);
      digitalWrite(LED_READY, LOW);
      delay(200);
    }
  }

  // Başlangıçta sensörü "KAPALI" konuma alıyoruz ki hafıza dolmasın
  stopSensorPhysically(); 
  
  Serial.println(F("SYSTEM_READY")); // F() makrosu RAM tasarrufu sağlar
}

void loop() {
  handleBluetoothLED();
  recvFromBLE();

  if (newData) {
    processCommand();
  }

  if (isMeasuring) {
    runMeasurement();
  }
}

// --- YENİ FONKSİYON: Sensörü ve Hafızayı Tamamen Temizleyip Durdurur ---
void stopSensorPhysically() {
  isMeasuring = false;
  
  // 1. Sensörü düşük güç moduna al (LED'leri kapatır, veri üretimini durdurur)
  sensor.shutDown(); 
  
  // 2. Sensörün içindeki birikmiş veriyi sil
  sensor.clearFIFO(); 
  
  // 3. Arduino'nun Seri portunda bekleyen çöp veri varsa temizle
  while(Serial.available() > 0) {
    Serial.read();
  }
  
  // Durum LED'lerini güncelle
  digitalWrite(LED_MEAS, LOW);
  digitalWrite(LED_READY, HIGH);
}

// --- YENİ FONKSİYON: Sensörü Sıfırdan Başlatır ---
void startSensorPhysically() {
  // 1. Sensörü uyandır
  sensor.wakeUp();
  
  // 2. Ayarları yeniden yükle (Her ölçümde taze başlangıç için)
  sensor.setup(50, 4, 2, 100, 411, 4096);
  
  // 3. FIFO'yu tekrar temizle (Emin olmak için)
  sensor.clearFIFO();
  
  isMeasuring = true;
  digitalWrite(LED_READY, LOW);
}

void handleBluetoothLED() {
  if (!bleConnected) {
    if (millis() - lastBlinkBLE > 500) {
      lastBlinkBLE = millis();
      digitalWrite(LED_BLE, !digitalRead(LED_BLE));
    }
  } else {
    digitalWrite(LED_BLE, HIGH);
  }
}

void recvFromBLE() {
  static byte ndx = 0;
  char endMarker = '\n';
  char rc;

  while (Serial.available() > 0 && newData == false) {
    rc = Serial.read();

    // Satır sonu karakteri veya Carriage Return (\r) gelirse dikkate alma
    if (rc != endMarker && rc != '\r') {
      receivedChars[ndx] = rc;
      ndx++;
      if (ndx >= numChars) {
        ndx = numChars - 1;
      }
    } else if (rc == endMarker) {
      receivedChars[ndx] = '\0'; // String sonlandırıcı
      ndx = 0;
      newData = true;
    }
  }
}

void processCommand() {
  // String nesnesi RAM'i şişirir ve kilitlenmeye sebep olur.
  // Bunun yerine char dizisi karşılaştırma (strcmp) kullanıyoruz.
  
  if (strcmp(receivedChars, "C") == 0) {
    bleConnected = true;
    digitalWrite(LED_READY, HIGH);
  } 
  else if (strcmp(receivedChars, "START") == 0) {
    startSensorPhysically();
  } 
  else if (strcmp(receivedChars, "STOP") == 0) {
    stopSensorPhysically();
    Serial.println(F("MEASUREMENT_STOPPED"));
  }

  newData = false;
}

void runMeasurement() {
  if (millis() - lastBlinkMeas > 100) {
    lastBlinkMeas = millis();
    digitalWrite(LED_MEAS, !digitalRead(LED_MEAS));
  }

  sensor.check();

  while (sensor.available()) {
    uint32_t red = sensor.getRed();
    uint32_t ir = sensor.getIR();

    Serial.print(F("RAW,"));
    Serial.print(millis());
    Serial.print(F(","));
    Serial.print(red);
    Serial.print(F(","));
    Serial.println(ir);

    sensor.nextSample();
  }
}