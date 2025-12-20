# BLE Health Monitoring System

## Proje Hakkında
Bu proje, fotopletismografi (PPG) prensiplerini kullanarak kalp atış hızı (BPM), kan oksijen doygunluğu (SpO2) ve perfüzyon indeksini (PI) gerçek zamanlı olarak izleyen entegre bir sistemdir. Sistem, Arduino tabanlı bir donanım katmanı ve Bluetooth Low Energy (BLE) protokolü üzerinden haberleşen modern bir iOS uygulamasından oluşmaktadır.

## Sistem Mimarisi
Sistem üç ana katmandan oluşmaktadır:
1.  **Donanım Katmanı:** MAX30102 sensörü ile ham verinin (Kızılötesi ve Kırmızı LED yansımaları) toplanması.
2.  **İletişim Katmanı:** Arduino üzerinden Seri-BLE dönüşümü ile verinin paketlenmesi ve iletilmesi.
3.  **Yazılım ve İşleme Katmanı:** Swift dili ile geliştirilmiş, istatistiksel filtreleme ve sinyal işleme algoritmalarını içeren iOS uygulaması.

## Donanım Özellikleri
### Bileşenler
- **Mikrodenetleyici:** Arduino (ATmega328P tabanlı yapı).
- **Sensör:** MAX30102 (Yüksek hassasiyetli Pulse Oximeter ve Heart-Rate sensörü).
- **Haberleşme:** BLE Modülü (Serial-over-BLE).

### Devre Şeması (Mantıksal Bağlantılar)
```text
MAX30102           Arduino
---------          -------
VCC      ------>   3.3V
GND      ------>   GND
SCL      ------>   A5 (veya I2C SCL)
SDA      ------>   A4 (veya I2C SDA)

Durum LED'leri:
Pin 8    ------>   BLE Bağlantı Durumu
Pin 9    ------>   Sistem Hazır Durumu
Pin 10   ------>   Ölçüm Aktif Durumu
```

## Sinyal İşleme ve Algoritmalar
Sistem, gürültüden arındırılmış kararlı ölçümler sunmak için aşağıdaki matematiksel modelleri kullanır:

### 1. Veri Filtreleme
Ham verideki yüksek frekanslı gürültüyü minimize etmek amacıyla 3 örneklem genişliğinde **Hareketli Ortalama (Moving Average)** filtresi uygulanmaktadır:
$y[n] = \frac{1}{M} \sum_{i=0}^{M-1} x[n-i]$

### 2. Kalp Atış Hızı (BPM) Tespiti
BPM hesaplaması için geliştirilmiş bir **Tepe Noktası Algılama (Peak Detection)** mekanizması kullanılmaktadır:
- **Dinamik Eşikleme:** Sinyal ortalaması ve genliğinin %20'si eklenerek bir eşik değeri ($T$) belirlenir.
- **Zaman Analizi:** Art arda gelen tepe noktaları arasındaki zaman farkı ($\Delta t$) üzerinden dakika bazlı frekans hesaplanır:
  $BPM = \frac{60 \times 1000}{\Delta t_{ms}}$

### 3. Oksijen Doygunluğu (SpO2) Hesaplaması
SpO2, "Oranların Oranı" (Ratio-of-Ratios) yöntemi ile hesaplanır. Kırmızı (RED) ve Kızılötesi (IR) kanallarının AC ve DC bileşenleri kullanılarak $R$ değeri elde edilir:
$R = \frac{(AC_{RED} / DC_{RED})}{(AC_{IR} / DC_{IR})}$
$SpO2 = 110 - 18 \times R$

### 4. Perfüzyon İndeksi (PI)
Sinyal kalitesini ölçmek için kullanılan perfüzyon indeksi, IR kanalındaki pulsatif akışın toplam akışa oranıdır:
$PI = (\frac{IR_{max} - IR_{min}}{IR_{mean}}) \times 100$

## Yazılım Uygulaması
iOS uygulaması SwiftUI mimarisi ile geliştirilmiş olup aşağıdaki teknik özelliklere sahiptir:
- **Gerçek Zamanlı Grafik:** Kızılötesi ve Kırmızı kanal verilerinin dinamik olarak görselleştirilmesi.
- **CoreBluetooth Entegrasyonu:** Düşük güç tüketimli kesintisiz veri aktarımı.
- **Haptik Geri Bildirim:** Kritik değerler ve bağlantı durumları için dokunsal uyarılar.
- **Raporlama Sistemi:** Ölçüm süresince toplanan verilerin istatistiksel özeti.

## Veri Paketi Yapısı
Arduino'dan iOS cihazına aktarılan veriler virgülle ayrılmış (CSV) formatta iletilir:
`RAW,Timestamp,RedValue,IRValue`
- **Timestamp:** Milisaniye cinsinden zaman damgası.
- **RedValue/IRValue:** 18-bit çözünürlüğünde ham ADC verisi.

## Kurulum ve Kullanım
1.  Arduino aygıtına `Arduino_Firmware/MAX30102_HardwareSerial.ino` dosyasını yükleyin.
2.  iOS uygulamasını Xcode üzerinden cihazınıza derleyin.
3.  Uygulama içerisinden BLE cihazınızı seçerek eşleştirin.
4.  Ölçümü başlat düğmesine basarak gerçek zamanlı verileri izleyin.
