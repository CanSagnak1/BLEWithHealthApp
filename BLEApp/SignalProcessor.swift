//
//  SignalProcessor.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 18.12.2025.
//

import Foundation

// Tek ve ana sonuç modeli
struct AnalysisResult: Identifiable {
    let id = UUID()
    let bpm: Int?
    let spo2: Int?
    let pi: Double
    let status: String
    let isSaturated: Bool

    // Rapor görünümü için yardımcı özellikler
    var bpmNote: String {
        if isSaturated { return "Doygunluk" }
        return (bpm ?? 0) > 50 ? "Güvenilir" : "Hesaplama..."
    }
    var spo2Note: String { pi > 0.5 ? "Stabil" : "Zayıf Sinyal" }
    var quality: String { isSaturated ? "ZAYIF" : (pi > 0.5 ? "İYİ" : "DÜŞÜK") }
    var qualityNote: String { status }
}

class SignalProcessor {
    static func process(times: [Double], reds: [Double], irs: [Double]) -> AnalysisResult {
        // En az 10 örnek (yaklaşık 1 saniye) veri kontrolü
        guard !irs.isEmpty && !reds.isEmpty && irs.count >= 10 else {
            return AnalysisResult(
                bpm: nil, spo2: nil, pi: 0, status: "Veri Bekleniyor", isSaturated: false)
        }

        // 1. Analiz Penceresi (Windowing)
        // Son 150 örneği (yaklaşık 12 saniye) alarak uzun süreli kaymaları (drift) önleyelim
        let maxSamples = 150
        let recentIrs = Array(irs.suffix(maxSamples))
        let recentReds = Array(reds.suffix(maxSamples))
        let recentTimes = Array(times.suffix(maxSamples))

        // 2. Doygunluk Kontrolü
        let saturationThreshold: Double = 262000
        let irMax = recentIrs.max() ?? 0
        let irIsSaturated = irMax > saturationThreshold

        // 3. Sinyal Seçimi
        // IR doygunsa RED kanalına geç
        let primarySignal = irIsSaturated ? recentReds : recentIrs

        // 4. Filtreleme
        let filteredSignal = applyMovingAverage(primarySignal, windowSize: 3)

        // 5. PI (Perfüzyon İndeksi) - Sadece son 150 örnekten
        let irMean = recentIrs.reduce(0, +) / Double(recentIrs.count)
        let irMin = recentIrs.min() ?? 0
        let currentPI = irMean > 0 ? ((irMax - irMin) / irMean) * 100 : 0

        // 6. Gelişmiş Peak Detection
        let sMin = filteredSignal.min() ?? 0
        let sMax = filteredSignal.max() ?? 0
        let sMean = filteredSignal.reduce(0, +) / Double(filteredSignal.count)
        let amplitude = sMax - sMin

        // Sinyal genliği çok düşükse gürültüdür
        if amplitude < (sMean * 0.0003) {  // %0.03 değişim bile yoksa
            return AnalysisResult(
                bpm: nil,
                spo2: irIsSaturated ? 98 : nil,
                pi: currentPI,
                status: irIsSaturated ? "Doygunluk Algılandı" : "Sinyal Çok Zayıf",
                isSaturated: irIsSaturated
            )
        }

        // Eşik değeri: Ortalama + Genliğin %20'si (Daha hassas yapıldı)
        let threshold = sMean + (amplitude * 0.2)

        var peakIndices = [Int]()
        var lastPeakIdx = -10
        let minSamplesBetween = 4  // ~150 BPM'e kadar destek (12Hz / 150 * 60 = 4.8)

        for i in 1..<filteredSignal.count - 1 {
            if filteredSignal[i] > threshold && filteredSignal[i] > filteredSignal[i - 1]
                && filteredSignal[i] > filteredSignal[i + 1]
            {

                if i - lastPeakIdx > minSamplesBetween {
                    peakIndices.append(i)
                    lastPeakIdx = i
                }
            }
        }

        // 7. BPM Hesaplama
        var bpmValue: Int? = nil
        if peakIndices.count >= 2 {
            let firstPeakIdx = peakIndices.first!
            let lastPeakIdx = peakIndices.last!

            let timeDiff = recentTimes[lastPeakIdx] - recentTimes[firstPeakIdx]
            if timeDiff > 1000 {  // En az 1 saniye aralık varsa
                let calculatedBPM = Int(Double(peakIndices.count - 1) * (60000.0 / timeDiff))
                if calculatedBPM > 40 && calculatedBPM < 200 {
                    bpmValue = calculatedBPM
                }
            }
        }

        // 8. SpO2 Hesaplama
        let redMean = recentReds.reduce(0, +) / Double(recentReds.count)
        let redMax = recentReds.max() ?? 0
        let redMin = recentReds.min() ?? 0

        let acRed = redMax - redMin
        let dcRed = redMean
        let acIr = irMax - irMin
        let dcIr = irMean

        var spo2Value: Int? = nil
        if dcRed > 0 && dcIr > 0 && acIr > 0 {
            let R = (acRed / dcRed) / (acIr / dcIr)
            let calculatedSpo2 = Int(110.0 - 18.0 * R)
            spo2Value = min(100, max(80, calculatedSpo2))
        } else if irIsSaturated {
            spo2Value = 97
        }

        let statusMessage =
            irIsSaturated
            ? "Sensör Doygunlukta"
            : (bpmValue != nil ? "Ölçüm Başarılı" : "Sinyal Analiz Ediliyor...")

        return AnalysisResult(
            bpm: bpmValue,
            spo2: spo2Value,
            pi: currentPI,
            status: statusMessage,
            isSaturated: irIsSaturated
        )
    }

    private static func applyMovingAverage(_ data: [Double], windowSize: Int) -> [Double] {
        guard data.count >= windowSize else { return data }
        var result = [Double]()
        for i in 0..<(data.count - windowSize + 1) {
            let window = data[i..<(i + windowSize)]
            let average = window.reduce(0, +) / Double(windowSize)
            result.append(average)
        }
        for _ in 0..<(windowSize - 1) {
            result.append(result.last ?? 0)
        }
        return result
    }
}
