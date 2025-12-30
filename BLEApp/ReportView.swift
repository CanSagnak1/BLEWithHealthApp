//
//  ReportView.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 18.12.2025.
//

import Charts
import SwiftUI

struct ReportView: View {
    let result: AnalysisResult
    @Environment(\.dismiss) var dismiss
    @State private var showContent = false
    @State private var showCheckmark = false
    @State private var expandedSections: Set<String> = ["technical"]

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.06)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    qualityBadgeSection
                        .padding(.horizontal, 20)

                    keyMetricsSection
                        .padding(.horizontal, 20)

                    if result.rmssd != nil || result.sdnn != nil {
                        hrvSection
                            .padding(.horizontal, 20)
                    }

                    perfusionSection
                        .padding(.horizontal, 20)

                    CollapsibleSection(
                        title: "TEKNİK DETAYLAR",
                        icon: "cpu.fill",
                        iconColor: .blue,
                        isExpanded: expandedSections.contains("technical"),
                        onToggle: { toggleSection("technical") }
                    ) {
                        technicalContent
                    }
                    .padding(.horizontal, 20)

                    actionButtonsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCheckmark = true
                }
            }
        }
    }

    private func toggleSection(_ id: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSections.contains(id) {
                expandedSections.remove(id)
            } else {
                expandedSections.insert(id)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()

                Button(action: {
                    HapticManager.shared.selection()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 40, height: 40)

                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }

            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .scaleEffect(showCheckmark ? 1 : 0.5)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.cyan)
                    .scaleEffect(showCheckmark ? 1 : 0.3)
            }

            Text("ANALİZ TAMAMLANDI")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text(currentDateTime())
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var qualityBadgeSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(qualityColor.opacity(0.15))
                    .frame(width: 54, height: 54)

                Image(systemName: qualityIcon)
                    .font(.system(size: 24))
                    .foregroundColor(qualityColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Ölçüm Kalitesi")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Text(result.quality)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(qualityColor)

                Text(result.status)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Sinyal")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Text("\(result.signalQuality)%")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.cyan)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(qualityColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var qualityColor: Color {
        result.isSaturated ? .red : (result.pi > 0.5 ? .green : .orange)
    }

    private var qualityIcon: String {
        result.isSaturated
            ? "sensor.tag.radiowaves.forward.fill"
            : (result.pi > 0.5 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
    }

    private var keyMetricsSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)

                Text("ANA METRİKLER")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            HStack(spacing: 12) {
                ReportMetricCard(
                    title: "NABIZ",
                    value: result.bpm.map { "\($0)" } ?? "---",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red,
                    note: result.bpm.map { healthNote(for: $0) }
                )

                ReportMetricCard(
                    title: "OKSİJEN",
                    value: result.spo2.map { "\($0)" } ?? "---",
                    unit: "%",
                    icon: "lungs.fill",
                    color: .cyan,
                    note: result.spo2.map { oxygenNote(for: $0) }
                )
            }
        }
    }

    private var hrvSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 12))
                    .foregroundColor(.purple)

                Text("KALP HIZI DEĞİŞKENLİĞİ (HRV)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            HStack(spacing: 12) {
                HRVReportCard(
                    title: "RMSSD",
                    value: result.rmssd.map { String(format: "%.0f", $0) } ?? "---",
                    unit: "ms",
                    description: "Kısa vadeli değişkenlik",
                    color: .purple
                )

                HRVReportCard(
                    title: "SDNN",
                    value: result.sdnn.map { String(format: "%.0f", $0) } ?? "---",
                    unit: "ms",
                    description: "Genel değişkenlik",
                    color: .indigo
                )
            }

            // Stress Level Card
            StressLevelCard(level: result.stressLevel, hrvStatus: result.hrvStatus)
        }
    }

    private var perfusionSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)

                Text("PERFÜZYON İNDEKSİ")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            HStack(spacing: 16) {
                PIGaugeView(value: result.pi)

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Değer")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))

                        Text(String(format: "%.2f%%", result.pi))
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.orange)
                    }

                    Text(piDescription)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(result.pi > 0.5 ? .green : .orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill((result.pi > 0.5 ? Color.green : Color.orange).opacity(0.15))
                        )
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private var piDescription: String {
        if result.pi > 1.0 { return "Mükemmel" }
        if result.pi > 0.5 { return "İyi" }
        if result.pi > 0.2 { return "Kabul Edilebilir" }
        return "Zayıf"
    }

    private var technicalContent: some View {
        VStack(spacing: 10) {
            TechnicalRow(icon: "waveform.path.ecg", label: "Sinyal Tipi", value: "PPG")
            TechnicalRow(icon: "checkmark.shield.fill", label: "Analiz", value: result.status)
            TechnicalRow(
                icon: "chart.bar.fill", label: "Sinyal Kalitesi", value: "\(result.signalQuality)%")
            TechnicalRow(icon: "clock.fill", label: "Zaman", value: currentDateTime())
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                HapticManager.shared.success()
                dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))

                    Text("RAPORU KAPAT")
                        .font(.system(size: 15, weight: .bold, design: .rounded))

                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }

            Text("Verileriniz sadece bu cihazda tutulur")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    private func currentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: Date())
    }

    private func healthNote(for bpm: Int) -> String {
        switch bpm {
        case 60...100: return "Normal"
        case 50..<60: return "Düşük"
        case 100...120: return "Yüksek"
        default: return "Dikkat"
        }
    }

    private func oxygenNote(for spo2: Int) -> String {
        switch spo2 {
        case 95...100: return "Normal"
        case 90..<95: return "Hafif Düşük"
        default: return "Düşük"
        }
    }
}

struct ReportMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let note: String?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            if let note = note {
                Text(note)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
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

struct HRVReportCard: View {
    let title: String
    let value: String
    let unit: String
    let description: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Text(description)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StressLevelCard: View {
    let level: StressLevel
    let hrvStatus: String

    private var color: Color {
        switch level {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .red
        case .unknown: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("STRES SEVİYESİ")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Text(level.rawValue)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("HRV Durumu")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Text(hrvStatus)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(14)
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

struct PIGaugeView: View {
    let value: Double

    private var progress: Double {
        min(value / 2.0, 1.0)
    }

    private var gaugeColor: Color {
        if value > 1.0 { return .green }
        if value > 0.5 { return .cyan }
        if value > 0.2 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
                .frame(width: 90, height: 90)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(gaugeColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 90, height: 90)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 18))
                    .foregroundColor(gaugeColor)

                Text("PI")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(iconColor)

                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.03))
                )
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                content
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.02))
                    )
                    .padding(.top, 2)
            }
        }
    }
}

struct TechnicalRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.cyan)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
    }
}
