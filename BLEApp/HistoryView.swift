//
//  HistoryView.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 30.12.2025.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: MeasurementStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedMeasurement: SavedMeasurement?
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.06)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if store.measurements.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            statsCards
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            measurementsList
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedMeasurement) { measurement in
            HistoryDetailView(measurement: measurement, store: store)
        }
        .alert("Tüm Geçmişi Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                store.clearAll()
            }
        } message: {
            Text("Tüm ölçüm geçmişi silinecek. Bu işlem geri alınamaz.")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button(action: {
                HapticManager.shared.selection()
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)

                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            VStack(spacing: 4) {
                Text("GEÇMİŞ RAPORLAR")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(store.measurements.count) ölçüm")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            if !store.measurements.isEmpty {
                Button(action: {
                    HapticManager.shared.warning()
                    showDeleteAlert = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color.white.opacity(0.02))
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 44))
                    .foregroundColor(.cyan.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text("Henüz Ölçüm Yok")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Ölçüm yaptığınızda geçmiş\nraporlarınız burada görünecek")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }

    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Bu Hafta",
                value: "\(store.measurementsThisWeek)",
                icon: "calendar",
                color: .cyan
            )

            StatCard(
                title: "Ort. Nabız",
                value: store.averageBPM.map { "\($0)" } ?? "---",
                icon: "heart.fill",
                color: .red
            )

            StatCard(
                title: "Ort. SpO₂",
                value: store.averageSpO2.map { "\($0)%" } ?? "---",
                icon: "lungs.fill",
                color: .blue
            )
        }
    }

    private var measurementsList: some View {
        VStack(spacing: 12) {
            HStack {
                Text("TÜM ÖLÇÜMLER")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
            }

            ForEach(store.measurements) { measurement in
                MeasurementRow(measurement: measurement)
                    .onTapGesture {
                        HapticManager.shared.selection()
                        selectedMeasurement = measurement
                    }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

struct MeasurementRow: View {
    let measurement: SavedMeasurement

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.formattedDate)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(measurement.formattedTime)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(measurement.bpmText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("BPM")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.red.opacity(0.8))
                }

                VStack(spacing: 2) {
                    Text(measurement.spo2Text)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("SpO₂")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan.opacity(0.8))
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct HistoryDetailView: View {
    let measurement: SavedMeasurement
    @ObservedObject var store: MeasurementStore
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.06)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    detailHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    metricsSection
                        .padding(.horizontal, 20)

                    hrvSection
                        .padding(.horizontal, 20)

                    infoSection
                        .padding(.horizontal, 20)

                    deleteButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .alert("Ölçümü Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                store.delete(measurement)
                dismiss()
            }
        } message: {
            Text("Bu ölçüm kalıcı olarak silinecek.")
        }
    }

    private var detailHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    HapticManager.shared.selection()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 40, height: 40)

                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()
            }

            VStack(spacing: 6) {
                Text(measurement.formattedDate)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text(measurement.formattedTime)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(qualityColor)
                    .frame(width: 8, height: 8)

                Text("Sinyal Kalitesi: \(measurement.signalQuality)%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(qualityColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(qualityColor.opacity(0.15))
            )
        }
    }

    private var qualityColor: Color {
        if measurement.signalQuality >= 70 { return .green }
        if measurement.signalQuality >= 40 { return .yellow }
        return .red
    }

    private var metricsSection: some View {
        HStack(spacing: 12) {
            DetailMetricCard(
                title: "NABIZ",
                value: measurement.bpmText,
                unit: "BPM",
                icon: "heart.fill",
                color: .red
            )

            DetailMetricCard(
                title: "OKSİJEN",
                value: measurement.spo2.map { "\($0)" } ?? "---",
                unit: "%",
                icon: "lungs.fill",
                color: .cyan
            )
        }
    }

    private var hrvSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("HRV METRİKLERİ")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
            }

            HStack(spacing: 12) {
                DetailInfoCard(
                    title: "RMSSD",
                    value: measurement.rmssd.map { String(format: "%.0f ms", $0) } ?? "---",
                    color: .purple
                )

                DetailInfoCard(
                    title: "SDNN",
                    value: measurement.sdnn.map { String(format: "%.0f ms", $0) } ?? "---",
                    color: .indigo
                )

                DetailInfoCard(
                    title: "STRES",
                    value: measurement.stressLevel,
                    color: stressColor
                )
            }
        }
    }

    private var stressColor: Color {
        switch measurement.stressLevel {
        case "Düşük": return .green
        case "Orta": return .yellow
        case "Yüksek": return .red
        default: return .gray
        }
    }

    private var infoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("DETAYLAR")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
            }

            VStack(spacing: 8) {
                DetailRow(
                    label: "Perfüzyon İndeksi", value: String(format: "%.2f%%", measurement.pi))
                DetailRow(label: "Durum", value: measurement.status)
                DetailRow(label: "Doygunluk", value: measurement.isSaturated ? "Evet" : "Hayır")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }

    private var deleteButton: some View {
        Button(action: {
            HapticManager.shared.warning()
            showDeleteAlert = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "trash")
                    .font(.system(size: 16))

                Text("Bu Ölçümü Sil")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct DetailMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DetailInfoCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
