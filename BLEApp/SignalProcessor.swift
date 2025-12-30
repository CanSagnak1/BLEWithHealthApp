//
//  SignalProcessor.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 18.12.2025.
//

import Foundation

struct AnalysisResult: Identifiable {
    let id = UUID()
    let bpm: Int?
    let spo2: Int?
    let pi: Double
    let status: String
    let isSaturated: Bool

    // HRV Metrics
    let rmssd: Double?
    let sdnn: Double?
    let stressLevel: StressLevel
    let signalQuality: Int

    var bpmNote: String {
        if isSaturated { return "Doygunluk" }
        return (bpm ?? 0) > 50 ? "Güvenilir" : "Hesaplama..."
    }

    var spo2Note: String { pi > 0.5 ? "Stabil" : "Zayıf Sinyal" }
    var quality: String { isSaturated ? "ZAYIF" : (pi > 0.5 ? "İYİ" : "DÜŞÜK") }
    var qualityNote: String { status }

    var hrvStatus: String {
        guard let rmssd = rmssd else { return "Hesaplanıyor" }
        if rmssd > 50 { return "Mükemmel" }
        if rmssd > 30 { return "İyi" }
        if rmssd > 20 { return "Orta" }
        return "Düşük"
    }
}

enum StressLevel: String {
    case low = "Düşük"
    case moderate = "Orta"
    case high = "Yüksek"
    case unknown = "Bilinmiyor"

    var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .high: return "red"
        case .unknown: return "gray"
        }
    }
}

class SignalProcessor {

    // MARK: - Constants
    private static let sampleRate: Double = 25.0
    private static let minBPM: Int = 40
    private static let maxBPM: Int = 200
    private static let saturationThreshold: Double = 262000
    private static let lowSignalThreshold: Double = 10000

    // SpO2 calibration lookup table (R-value to SpO2)
    private static let spo2LookupTable: [(r: Double, spo2: Int)] = [
        (0.40, 100), (0.50, 99), (0.60, 98), (0.70, 97),
        (0.80, 96), (0.85, 95), (0.90, 94), (0.95, 93),
        (1.00, 92), (1.10, 90), (1.20, 88), (1.30, 86),
        (1.40, 84), (1.50, 82), (1.60, 80), (1.70, 78),
        (1.80, 76), (1.90, 74), (2.00, 72),
    ]

    // MARK: - Main Processing Function
    static func process(times: [Double], reds: [Double], irs: [Double]) -> AnalysisResult {
        guard !irs.isEmpty && !reds.isEmpty && irs.count >= 20 else {
            return AnalysisResult(
                bpm: nil, spo2: nil, pi: 0,
                status: "Veri Bekleniyor", isSaturated: false,
                rmssd: nil, sdnn: nil, stressLevel: .unknown,
                signalQuality: 0
            )
        }

        // 1. Window the data (last 300 samples ~ 12 seconds at 25Hz)
        let windowSize = min(300, irs.count)
        let recentIrs = Array(irs.suffix(windowSize))
        let recentReds = Array(reds.suffix(windowSize))
        let recentTimes = Array(times.suffix(windowSize))

        // 2. Check for saturation and low signal
        let irMax = recentIrs.max() ?? 0
        let irMin = recentIrs.min() ?? 0
        let isSaturated = irMax > saturationThreshold
        let isLowSignal = irMax < lowSignalThreshold

        // 3. Calculate signal quality (0-100)
        let signalQuality = calculateSignalQuality(irs: recentIrs, reds: recentReds)

        if isLowSignal {
            return AnalysisResult(
                bpm: nil, spo2: nil, pi: 0,
                status: "Sensör Teması Yok", isSaturated: false,
                rmssd: nil, sdnn: nil, stressLevel: .unknown,
                signalQuality: signalQuality
            )
        }

        // 4. Select primary signal (use RED if IR is saturated)
        let primarySignal = isSaturated ? recentReds : recentIrs

        // 5. Apply band-pass filter (removes DC offset and high-frequency noise)
        let filteredSignal = applyBandPassFilter(primarySignal)

        // 6. Calculate Perfusion Index
        let irMean = recentIrs.reduce(0, +) / Double(recentIrs.count)
        let pi = irMean > 0 ? ((irMax - irMin) / irMean) * 100 : 0

        // 7. Advanced Peak Detection
        let peakIndices = detectPeaksAdaptive(signal: filteredSignal)

        // 8. Calculate BPM from peaks
        var bpmValue: Int? = nil
        var rrIntervals: [Double] = []

        if peakIndices.count >= 3 && recentTimes.count > peakIndices.last! {
            // Calculate RR intervals in milliseconds
            for i in 1..<peakIndices.count {
                let prevIdx = peakIndices[i - 1]
                let currIdx = peakIndices[i]
                if prevIdx < recentTimes.count && currIdx < recentTimes.count {
                    let rrInterval = recentTimes[currIdx] - recentTimes[prevIdx]
                    if rrInterval > 300 && rrInterval < 1500 {  // Valid RR: 40-200 BPM
                        rrIntervals.append(rrInterval)
                    }
                }
            }

            if rrIntervals.count >= 2 {
                let avgRR = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
                let calculatedBPM = Int(60000.0 / avgRR)
                if calculatedBPM >= minBPM && calculatedBPM <= maxBPM {
                    bpmValue = calculatedBPM
                }
            }
        }

        // 9. Calculate HRV metrics
        let (rmssd, sdnn) = calculateHRV(rrIntervals: rrIntervals)
        let stressLevel = calculateStressLevel(rmssd: rmssd, sdnn: sdnn)

        // 10. Calculate SpO2 with proper calibration
        let spo2Value = calculateSpO2(
            reds: recentReds,
            irs: recentIrs,
            isSaturated: isSaturated
        )

        // 11. Generate status message
        let statusMessage: String
        if isSaturated {
            statusMessage = "Sensör Doygunlukta"
        } else if bpmValue != nil && spo2Value != nil {
            statusMessage = "Ölçüm Başarılı"
        } else if signalQuality > 50 {
            statusMessage = "Sinyal Analiz Ediliyor..."
        } else {
            statusMessage = "Sinyal Kalitesi Düşük"
        }

        return AnalysisResult(
            bpm: bpmValue,
            spo2: spo2Value,
            pi: pi,
            status: statusMessage,
            isSaturated: isSaturated,
            rmssd: rmssd,
            sdnn: sdnn,
            stressLevel: stressLevel,
            signalQuality: signalQuality
        )
    }

    // MARK: - Band-Pass Filter (0.5-4 Hz for heart rate)
    private static func applyBandPassFilter(_ data: [Double]) -> [Double] {
        guard data.count > 10 else { return data }

        // Step 1: Remove DC offset (high-pass)
        let mean = data.reduce(0, +) / Double(data.count)
        var acSignal = data.map { $0 - mean }

        // Step 2: Apply Savitzky-Golay smoothing (low-pass approximation)
        acSignal = applySavitzkyGolay(acSignal, windowSize: 5)

        // Step 3: Apply second-order difference (emphasizes peaks)
        var filtered = [Double](repeating: 0, count: acSignal.count)
        for i in 2..<acSignal.count {
            filtered[i] = acSignal[i] - 2 * acSignal[i - 1] + acSignal[i - 2]
        }

        // Normalize
        let maxAbs = filtered.map { abs($0) }.max() ?? 1.0
        if maxAbs > 0 {
            filtered = filtered.map { $0 / maxAbs }
        }

        return filtered
    }

    // MARK: - Savitzky-Golay Smoothing
    private static func applySavitzkyGolay(_ data: [Double], windowSize: Int) -> [Double] {
        guard data.count >= windowSize else { return data }

        let halfWindow = windowSize / 2
        var result = data

        for i in halfWindow..<(data.count - halfWindow) {
            var sum = 0.0
            for j in -halfWindow...halfWindow {
                sum += data[i + j]
            }
            result[i] = sum / Double(windowSize)
        }

        return result
    }

    // MARK: - Adaptive Peak Detection
    private static func detectPeaksAdaptive(signal: [Double]) -> [Int] {
        guard signal.count > 20 else { return [] }

        var peaks: [Int] = []

        // Calculate adaptive threshold
        let sortedAbs = signal.map { abs($0) }.sorted()
        let threshold = sortedAbs[Int(Double(sortedAbs.count) * 0.7)]

        // Minimum samples between peaks (for max 200 BPM at 25 Hz)
        let minDistance = Int(sampleRate * 60.0 / Double(maxBPM))

        // Find peaks using first derivative sign change
        var lastPeakIdx = -minDistance

        for i in 2..<(signal.count - 2) {
            // Check if local maximum
            let isLocalMax =
                signal[i] > signal[i - 1] && signal[i] > signal[i + 1] && signal[i] > signal[i - 2]
                && signal[i] > signal[i + 2]

            // Check if above threshold
            let isAboveThreshold = signal[i] > threshold

            // Check minimum distance
            let hasMinDistance = (i - lastPeakIdx) >= minDistance

            if isLocalMax && isAboveThreshold && hasMinDistance {
                peaks.append(i)
                lastPeakIdx = i
            }
        }

        return peaks
    }

    // MARK: - HRV Calculation
    private static func calculateHRV(rrIntervals: [Double]) -> (rmssd: Double?, sdnn: Double?) {
        guard rrIntervals.count >= 3 else { return (nil, nil) }

        // SDNN: Standard deviation of NN intervals
        let mean = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
        let squaredDiffs = rrIntervals.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(rrIntervals.count)
        let sdnn = sqrt(variance)

        // RMSSD: Root mean square of successive differences
        var successiveDiffs: [Double] = []
        for i in 1..<rrIntervals.count {
            let diff = rrIntervals[i] - rrIntervals[i - 1]
            successiveDiffs.append(diff * diff)
        }

        guard !successiveDiffs.isEmpty else { return (nil, sdnn) }

        let meanSquaredDiff = successiveDiffs.reduce(0, +) / Double(successiveDiffs.count)
        let rmssd = sqrt(meanSquaredDiff)

        return (rmssd, sdnn)
    }

    // MARK: - Stress Level Calculation
    private static func calculateStressLevel(rmssd: Double?, sdnn: Double?) -> StressLevel {
        guard let rmssd = rmssd else { return .unknown }

        // Lower HRV generally indicates higher stress
        if rmssd > 50 {
            return .low
        } else if rmssd > 25 {
            return .moderate
        } else {
            return .high
        }
    }

    // MARK: - SpO2 Calculation with Calibration
    private static func calculateSpO2(reds: [Double], irs: [Double], isSaturated: Bool) -> Int? {
        guard !reds.isEmpty && !irs.isEmpty else { return nil }

        let redMean = reds.reduce(0, +) / Double(reds.count)
        let redMax = reds.max() ?? 0
        let redMin = reds.min() ?? 0

        let irMean = irs.reduce(0, +) / Double(irs.count)
        let irMax = irs.max() ?? 0
        let irMin = irs.min() ?? 0

        // Calculate AC and DC components
        let acRed = redMax - redMin
        let dcRed = redMean
        let acIr = irMax - irMin
        let dcIr = irMean

        // Validate signals
        guard dcRed > 0 && dcIr > 0 && acIr > 0 else {
            return isSaturated ? 97 : nil
        }

        // Calculate R value (ratio of ratios)
        let R = (acRed / dcRed) / (acIr / dcIr)

        // Use lookup table for SpO2
        var spo2 = interpolateSpO2(R: R)

        // Clamp to valid range
        spo2 = min(100, max(70, spo2))

        return spo2
    }

    // MARK: - SpO2 Interpolation from Lookup Table
    private static func interpolateSpO2(R: Double) -> Int {
        // Find the two closest entries
        var lowerEntry = spo2LookupTable.first!
        var upperEntry = spo2LookupTable.last!

        for entry in spo2LookupTable {
            if entry.r <= R {
                lowerEntry = entry
            }
            if entry.r >= R {
                upperEntry = entry
                break
            }
        }

        // Linear interpolation
        if lowerEntry.r == upperEntry.r {
            return lowerEntry.spo2
        }

        let ratio = (R - lowerEntry.r) / (upperEntry.r - lowerEntry.r)
        let spo2 = Double(lowerEntry.spo2) - ratio * Double(lowerEntry.spo2 - upperEntry.spo2)

        return Int(spo2)
    }

    // MARK: - Signal Quality Assessment
    private static func calculateSignalQuality(irs: [Double], reds: [Double]) -> Int {
        guard !irs.isEmpty else { return 0 }

        var score = 100

        // Check for saturation
        let irMax = irs.max() ?? 0
        if irMax > saturationThreshold {
            score -= 30
        }

        // Check for low signal
        if irMax < lowSignalThreshold {
            score -= 40
        }

        // Check signal variability (too flat is bad)
        let irMin = irs.min() ?? 0
        let irMean = irs.reduce(0, +) / Double(irs.count)
        let variability = irMean > 0 ? (irMax - irMin) / irMean : 0

        if variability < 0.001 {
            score -= 30
        } else if variability < 0.005 {
            score -= 15
        }

        // Check for noise (high frequency content)
        var diffSum = 0.0
        for i in 1..<irs.count {
            diffSum += abs(irs[i] - irs[i - 1])
        }
        let avgDiff = diffSum / Double(irs.count - 1)
        let noiseRatio = irMean > 0 ? avgDiff / irMean : 0

        if noiseRatio > 0.1 {
            score -= 20
        } else if noiseRatio > 0.05 {
            score -= 10
        }

        return max(0, min(100, score))
    }
}
