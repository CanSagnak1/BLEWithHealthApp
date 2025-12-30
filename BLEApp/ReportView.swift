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
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.06, green: 0.06, blue: 0.10),
                    Color(red: 0.04, green: 0.04, blue: 0.07),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    qualityBadgeSection
                        .padding(.horizontal, 20)

                    keyMetricsSection
                        .padding(.horizontal, 20)

                    perfusionGaugeSection
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
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    showCheckmark = true
                }
            }
        }
    }

    private func toggleSection(_ id: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if expandedSections.contains(id) {
                expandedSections.remove(id)
            } else {
                expandedSections.insert(id)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()

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
                .accessibilityLabel("Kapat")
            }

            AnimatedSuccessIcon(isShowing: $showCheckmark)

            Text("ANALİZ TAMAMLANDI")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(currentDateTime())
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var qualityBadgeSection: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(qualityColor.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: qualityIcon)
                    .font(.system(size: 28))
                    .foregroundColor(qualityColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Ölçüm Kalitesi")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Text(result.quality)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(qualityColor)

                Text(result.status)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Güven")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Text("\(Int(min(result.pi * 10, 100)))%")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.cyan)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [qualityColor.opacity(0.4), qualityColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
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

            VStack(spacing: 14) {
                ReportMetricCard(
                    title: "NABIZ",
                    value: result.bpm.map { "\($0)" } ?? "---",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red,
                    interpretation: result.bpm.map { healthMessage(for: $0) },
                    interpretationColor: result.bpm.map { healthColor(for: $0) }
                )

                ReportMetricCard(
                    title: "OKSİJEN DOYGUNLUĞU",
                    value: result.spo2.map { "\($0)" } ?? "---",
                    unit: "%",
                    icon: "lungs.fill",
                    color: .cyan,
                    interpretation: result.spo2.map { oxygenMessage(for: $0) },
                    interpretationColor: result.spo2.map { oxygenColor(for: $0) }
                )
            }
        }
    }

    private var perfusionGaugeSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)

                Text("PERFÜZYON İNDEKSİ")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            HStack(spacing: 24) {
                PIGaugeView(value: result.pi)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Değer")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))

                        Text(String(format: "%.2f%%", result.pi))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.orange)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(result.pi > 0.5 ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)

                        Text(
                            result.pi > 1.0
                                ? "Mükemmel"
                                : result.pi > 0.5
                                    ? "İyi" : result.pi > 0.2 ? "Kabul Edilebilir" : "Zayıf"
                        )
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(result.pi > 0.5 ? .green : .orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((result.pi > 0.5 ? Color.green : Color.orange).opacity(0.15))
                    )
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var technicalContent: some View {
        VStack(spacing: 12) {
            TechnicalRow(
                icon: "waveform.path.ecg", label: "Sinyal Tipi", value: "PPG (Fotopletysmografi)")
            TechnicalRow(
                icon: "checkmark.shield.fill", label: "Analiz Durumu", value: result.status)
            TechnicalRow(icon: "medal.fill", label: "Güvenilirlik", value: result.quality)
            TechnicalRow(icon: "clock.fill", label: "İşlem Zamanı", value: currentDateTime())
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 14) {
            Button(action: {
                HapticManager.shared.success()
                dismiss()
            }) {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))

                    Text("RAPORU KAPAT")
                        .font(.system(size: 16, weight: .bold, design: .rounded))

                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.blue.opacity(0.4), radius: 16, y: 8)
            }

            HStack(spacing: 12) {
                ShareButton(icon: "square.and.arrow.up", label: "Paylaş")
                ShareButton(icon: "doc.fill", label: "PDF")
            }

            Text("Sağlık verileriniz sadece bu cihazda tutulur")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }

    private func currentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: Date())
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
        case 60...100: return "Normal dinlenme nabzı"
        case 50..<60: return "Normalin altında"
        case 100...120: return "Yüksek nabız"
        default: return "Olağandışı değer"
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
        case 95...100: return "Normal oksijen seviyesi"
        case 90..<95: return "Hafif düşük"
        default: return "Düşük - dikkat"
        }
    }
}

struct AnimatedSuccessIcon: View {
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.cyan.opacity(0.2), .blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 90, height: 90)
                .scaleEffect(isShowing ? 1 : 0.5)
                .opacity(isShowing ? 1 : 0)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isShowing ? 1 : 0.3)
                .rotationEffect(.degrees(isShowing ? 0 : -180))
        }
    }
}

struct ReportMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let interpretation: String?
    let interpretationColor: Color?

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text(unit)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                if let interpretation = interpretation, let interpColor = interpretationColor {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(interpColor)
                            .frame(width: 6, height: 6)

                        Text(interpretation)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(interpColor)
                    }
                }
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.4), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}

struct PIGaugeView: View {
    let value: Double
    @State private var animatedValue: Double = 0

    private var progress: Double {
        min(animatedValue / 2.0, 1.0)
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
                .stroke(Color.white.opacity(0.1), lineWidth: 10)
                .frame(width: 100, height: 100)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [gaugeColor.opacity(0.3), gaugeColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(gaugeColor)

                Text("PI")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedValue = value
            }
        }
        .accessibilityLabel("Perfüzyon indeksi: \(String(format: "%.2f", value)) yüzde")
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
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)

                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: isExpanded ? 16 : 16)
                        .fill(Color.white.opacity(0.03))
                )
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                content
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.02))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct TechnicalRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

struct ShareButton: View {
    let icon: String
    let label: String

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))

                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
