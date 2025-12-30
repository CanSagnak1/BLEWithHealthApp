//
//  MeasurementStore.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 30.12.2025.
//

import Combine
import Foundation
import SwiftUI

struct SavedMeasurement: Identifiable, Codable {
    let id: UUID
    let date: Date
    let bpm: Int?
    let spo2: Int?
    let pi: Double
    let rmssd: Double?
    let sdnn: Double?
    let stressLevel: String
    let signalQuality: Int
    let status: String
    let isSaturated: Bool

    init(from result: AnalysisResult) {
        self.id = UUID()
        self.date = Date()
        self.bpm = result.bpm
        self.spo2 = result.spo2
        self.pi = result.pi
        self.rmssd = result.rmssd
        self.sdnn = result.sdnn
        self.stressLevel = result.stressLevel.rawValue
        self.signalQuality = result.signalQuality
        self.status = result.status
        self.isSaturated = result.isSaturated
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    var qualityText: String {
        if signalQuality >= 70 { return "İyi" }
        if signalQuality >= 40 { return "Orta" }
        return "Zayıf"
    }

    var bpmText: String {
        bpm.map { "\($0)" } ?? "---"
    }

    var spo2Text: String {
        spo2.map { "\($0)%" } ?? "---"
    }
}

class MeasurementStore: ObservableObject {
    @Published var measurements: [SavedMeasurement] = []

    private let storageKey = "saved_measurements"
    private let maxMeasurements = 100

    init() {
        loadMeasurements()
    }

    func save(_ result: AnalysisResult) {
        let measurement = SavedMeasurement(from: result)
        measurements.insert(measurement, at: 0)

        // Keep only last 100 measurements
        if measurements.count > maxMeasurements {
            measurements = Array(measurements.prefix(maxMeasurements))
        }

        saveToDisk()
    }

    func delete(at offsets: IndexSet) {
        measurements.remove(atOffsets: offsets)
        saveToDisk()
    }

    func delete(_ measurement: SavedMeasurement) {
        measurements.removeAll { $0.id == measurement.id }
        saveToDisk()
    }

    func clearAll() {
        measurements.removeAll()
        saveToDisk()
    }

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(measurements)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save measurements: \(error)")
        }
    }

    private func loadMeasurements() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            measurements = try JSONDecoder().decode([SavedMeasurement].self, from: data)
        } catch {
            print("Failed to load measurements: \(error)")
        }
    }

    // Statistics
    var averageBPM: Int? {
        let validBPMs = measurements.compactMap { $0.bpm }
        guard !validBPMs.isEmpty else { return nil }
        return validBPMs.reduce(0, +) / validBPMs.count
    }

    var averageSpO2: Int? {
        let validSpO2s = measurements.compactMap { $0.spo2 }
        guard !validSpO2s.isEmpty else { return nil }
        return validSpO2s.reduce(0, +) / validSpO2s.count
    }

    var measurementsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return measurements.filter { $0.date >= weekAgo }.count
    }
}
