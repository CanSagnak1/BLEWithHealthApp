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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.06, green: 0.06, blue: 0.1),
                    Color(red: 0.04, green: 0.04, blue: 0.07),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                        .padding(.horizontal)
                        .padding(.top, 20)

                    qualityBadgeSection
                        .padding(.horizontal)

                    keyMetricsSection
                        .padding(.horizontal)

                    detailedAnalyticsSection
                        .padding(.horizontal)

                    technicalMetricsSection
                        .padding(.horizontal)

                    actionButtonsSection
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()

                Button(action: {
                    HapticManager.shared.selection()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Image(systemName: "chart.bar.doc.horizontal.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 8)

            Text("BİYOSİNYAL ANALİZ RAPORU")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(currentDateTime())
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var qualityBadgeSection: some View {
        HStack(spacing: 16) {
            Image(
                systemName: result.isSaturated
                    ? "sensor.tag.radiowaves.forward.fill"
                    : (result.pi > 0.5
                        ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
            )
            .font(.system(size: 24))
            .foregroundColor(result.isSaturated ? .red : (result.pi > 0.5 ? .green : .orange))

            VStack(alignment: .leading, spacing: 4) {
                Text("Ölçüm Kalitesi")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Text(result.quality)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(
                        result.isSaturated ? .red : (result.pi > 0.5 ? .green : .orange))

                Text(result.status)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Güven Skoru")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Text("\(Int(min(result.pi * 10, 100)))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            result.pi > 0.5 ? Color.green.opacity(0.4) : Color.orange.opacity(0.4),
                            result.pi > 0.5 ? Color.green.opacity(0.1) : Color.orange.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    private var keyMetricsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)

                Text("ANA METRİKLER")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            HStack(spacing: 16) {
                heartRateCard
                oxygenCard
            }
        }
    }

    private var heartRateCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("NABIZ")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(result.bpm.map { "\($0)" } ?? "---")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("BPM")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Text(result.bpmNote)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.15))
                    )
            }

            if let bpm = result.bpm {
                healthInterpretation(for: bpm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.red.opacity(0.4), .pink.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.red.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    private var oxygenCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "lungs.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("OKSİJEN")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(result.spo2.map { "\($0)" } ?? "---")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("%")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Text(result.spo2Note)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.cyan.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.15))
                    )
            }

            if let spo2 = result.spo2 {
                oxygenInterpretation(for: spo2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.cyan.opacity(0.4), .blue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.cyan.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    private var detailedAnalyticsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 14))
                    .foregroundColor(.purple)

                Text("DETAYLI ANALİZ")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            perfusionIndexCard
        }
    }

    private var perfusionIndexCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)

                        Text("Perfüzyon İndeksi (PI)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Text("Kan akış kalitesi göstergesi")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f%%", result.pi))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)

                    Text(result.pi > 0.5 ? "İyi" : "Düşük")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(result.pi > 0.5 ? .green : .orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((result.pi > 0.5 ? Color.green : Color.orange).opacity(0.15))
                        )
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 8) {
                Text("Yorumlama Kılavuzu")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                piInterpretationGuide
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var piInterpretationGuide: some View {
        VStack(spacing: 8) {
            InterpretationRow(
                icon: "checkmark.circle.fill",
                color: .green,
                range: "> 1.0%",
                meaning: "Mükemmel sinyal kalitesi"
            )
            InterpretationRow(
                icon: "checkmark.circle",
                color: .green,
                range: "0.5% - 1.0%",
                meaning: "İyi sinyal kalitesi"
            )
            InterpretationRow(
                icon: "exclamationmark.circle",
                color: .orange,
                range: "0.2% - 0.5%",
                meaning: "Kabul edilebilir sinyal"
            )
            InterpretationRow(
                icon: "xmark.circle",
                color: .red,
                range: "< 0.2%",
                meaning: "Zayıf sinyal - tekrar deneyin"
            )
        }
    }

    private var technicalMetricsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)

                Text("TEKNİK DETAYLAR")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            VStack(spacing: 12) {
                TechnicalMetricRow(
                    label: "Sinyal Tipi",
                    value: "PPG (Fotopletysmografi)",
                    icon: "waveform.path.ecg"
                )
                TechnicalMetricRow(
                    label: "Analiz Durumu",
                    value: result.status,
                    icon: "checkmark.shield.fill"
                )
                TechnicalMetricRow(
                    label: "Güvenilirlik",
                    value: result.quality,
                    icon: "medal.fill"
                )
                TechnicalMetricRow(
                    label: "İşlem Zamanı",
                    value: currentDateTime(),
                    icon: "clock.fill"
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
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

                    Image(systemName: "arrow.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.blue.opacity(0.3), radius: 12, y: 6)
            }

            Text("Sağlık verileriniz sadece bu cihazda tutulur")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }

    private func healthInterpretation(for bpm: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 4)

            HStack(spacing: 6) {
                Image(systemName: healthIcon(for: bpm))
                    .font(.system(size: 12))
                    .foregroundColor(healthColor(for: bpm))

                Text(healthMessage(for: bpm))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private func oxygenInterpretation(for spo2: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 4)

            HStack(spacing: 6) {
                Image(systemName: oxygenIcon(for: spo2))
                    .font(.system(size: 12))
                    .foregroundColor(oxygenColor(for: spo2))

                Text(oxygenMessage(for: spo2))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private func currentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: Date())
    }

    private func healthIcon(for bpm: Int) -> String {
        switch bpm {
        case 60...100: return "checkmark.circle.fill"
        case 50..<60, 100...120: return "info.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private func healthColor(for bpm: Int) -> Color {
        switch bpm {
        case 60...100: return .green
        case 50..<60, 100...120: return .orange
        default: return .red
        }
    }

    private func healthMessage(for bpm: Int) -> String {
        switch bpm {
        case 60...100: return "Normal dinlenme nabzı aralığında"
        case 50..<60: return "Dinlenme nabzı normalin altında"
        case 100...120: return "Dinlenme nabzı yüksek"
        default: return "Olağandışı değer - tekrar ölçün"
        }
    }

    private func oxygenIcon(for spo2: Int) -> String {
        switch spo2 {
        case 95...100: return "checkmark.circle.fill"
        case 90..<95: return "info.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private func oxygenColor(for spo2: Int) -> Color {
        switch spo2 {
        case 95...100: return .green
        case 90..<95: return .orange
        default: return .red
        }
    }

    private func oxygenMessage(for spo2: Int) -> String {
        switch spo2 {
        case 95...100: return "Normal oksijen doygunluğu"
        case 90..<95: return "Hafif düşük oksijen seviyesi"
        default: return "Düşük oksijen - doktora danışın"
        }
    }
}

struct InterpretationRow: View {
    let icon: String
    let color: Color
    let range: String
    let meaning: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 20)

            Text(range)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 80, alignment: .leading)

            Text(meaning)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TechnicalMetricRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
