# BLE Health Monitoring System

## Proje Hakkında

Fotopletismografi (PPG) prensiplerini kullanarak kalp atış hızı (BPM), kan oksijen doygunluğu (SpO2), perfüzyon indeksi (PI) ve kalp hızı değişkenliği (HRV) metriklerini gerçek zamanlı olarak izleyen entegre bir sistemdir.

**Temel Özellikler:**
- Gerçek zamanlı nabız ve oksijen ölçümü
- HRV metrikleri (RMSSD, SDNN) ve stres seviyesi analizi
- Ölçüm geçmişi kaydetme ve görüntüleme
- Modern, minimalist iOS arayüzü

---

## Sistem Mimarisi

| Katman | Açıklama |
|--------|----------|
| **Donanım** | MAX30102 sensörü ile ham veri toplama |
| **İletişim** | Arduino üzerinden Serial-BLE protokolü |
| **Yazılım** | Swift/SwiftUI ile sinyal işleme ve görselleştirme |

---

## Donanım

### Bileşenler
- **Mikrodenetleyici:** Arduino (ATmega328P)
- **Sensör:** MAX30102 Pulse Oximeter
- **Haberleşme:** BLE Modülü

### Bağlantı Şeması
```
MAX30102           Arduino
---------          -------
VCC      ------>   3.3V
GND      ------>   GND
SCL      ------>   A5 (I2C SCL)
SDA      ------>   A4 (I2C SDA)

Durum LED'leri:
Pin 8    ------>   BLE Bağlantı
Pin 9    ------>   Sistem Hazır
Pin 10   ------>   Ölçüm Aktif
```

---

## Sinyal İşleme Algoritmaları

### 1. Band-Pass Filtreleme
DC offset kaldırma ve Savitzky-Golay smoothing ile gürültü azaltma:
- Yüksek geçiren: DC bileşeni kaldırma
- Düşük geçiren: Yüksek frekans gürültüsü filtreleme

### 2. Adaptif Peak Detection
Türev bazlı tepe noktası algılama:
- Dinamik eşik değerleri
- Minimum mesafe kontrolü (40-200 BPM aralığı)

### 3. BPM Hesaplama
RR aralıklarından kalp atış hızı:
```
BPM = 60000 / ortalama_RR_aralığı(ms)
```

### 4. SpO2 Hesaplama
R-değeri lookup table ile kalibrasyon:
```
R = (AC_RED / DC_RED) / (AC_IR / DC_IR)
SpO2 = lookup_table(R)  // 0.4-2.0 arası R değerleri için
```

### 5. HRV Metrikleri
- **RMSSD:** Ardışık RR farkları kareleri ortalamasının karekökü
- **SDNN:** RR aralıklarının standart sapması
- **Stres Seviyesi:** RMSSD bazlı tahmin (Düşük/Orta/Yüksek)

### 6. Perfüzyon İndeksi
```
PI = ((IR_max - IR_min) / IR_ortalama) × 100
```

---

## iOS Uygulaması

### Özellikler

| Özellik | Açıklama |
|---------|----------|
| **Gerçek Zamanlı Grafikler** | IR ve RED kanal görselleştirme |
| **Canlı Metrikler** | BPM, SpO2, PI, HRV, Stres |
| **Sinyal Kalitesi** | 0-100 arası kalite skoru |
| **Ölçüm Geçmişi** | Son 100 ölçüm kaydı |
| **Detaylı Raporlar** | HRV analizi dahil |
| **Haptik Geri Bildirim** | Dokunsal uyarılar |

### Dosya Yapısı
```
BLEApp/
├── ContentView.swift        # Ana ekran
├── BluetoothManager.swift   # BLE iletişim
├── SignalProcessor.swift    # Sinyal işleme algoritmaları
├── MeasurementStore.swift   # Veri kalıcılığı
├── HistoryView.swift        # Geçmiş raporlar
├── ReportView.swift         # Analiz raporu
├── DevicePickerView.swift   # Cihaz seçimi
├── ChartComponents.swift    # Grafik bileşenleri
└── HapticManager.swift      # Haptik yönetimi
```

---

## Veri Protokolü

Arduino'dan iOS'a CSV formatında veri:
```
RAW,Timestamp,RedValue,IRValue
```
- **Timestamp:** Milisaniye
- **RedValue/IRValue:** 18-bit ADC verisi

---

## Kurulum

1. Arduino'ya `Arduino_Firmware/MAX30102_HardwareSerial.ino` yükleyin
2. iOS uygulamasını Xcode ile derleyin
3. BLE cihazı seçip eşleştirin
4. "Ölçümü Başlat" ile 30 saniyelik ölçüm yapın

---

## Performans Optimizasyonları

- **Ring Buffer:** 500 örnek bellek limiti
- **Background Processing:** UI thread koruması
- **Batch Updates:** 5 veri birden güncelleme
- **Veri Doğrulama:** Spike filtreleme

---

## Gereksinimler

- iOS 18.0+
- Xcode 16+
- Arduino IDE
- MAX30102 sensör modülü
- BLE uyumlu Arduino
