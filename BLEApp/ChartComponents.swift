//
//  ChartComponents.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 19.12.2025.
//

import Charts
import SwiftUI

struct HeartRateChartView: View {
    let data: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            statsRow
            chartContent
        }
        .background(backgroundStyle)
    }

    private var headerView: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("NABIZ SİNYALİ")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Text("Kızılötesi (IR) Kanal")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            if !data.isEmpty {
                Text("\(data.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var statsRow: some View {
        Group {
            if data.count > 10 {
                let displayData = Array(data.suffix(100))
                let minValue = displayData.min() ?? 0
                let maxValue = displayData.max() ?? 0
                let avgValue = displayData.reduce(0, +) / Double(displayData.count)

                HStack(spacing: 12) {
                    StatBadge(label: "Min", value: String(format: "%.0f", minValue), color: .blue)
                    StatBadge(label: "Ort", value: String(format: "%.0f", avgValue), color: .green)
                    StatBadge(label: "Max", value: String(format: "%.0f", maxValue), color: .red)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var chartContent: some View {
        ZStack {
            if data.isEmpty {
                emptyStateView
            } else {
                actualChart
            }
        }
        .frame(height: 160)
        .background(chartBackground)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 32))
                .foregroundColor(.red.opacity(0.3))

            Text("Sinyal bekleniyor...")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var actualChart: some View {
        let displayData = Array(data.suffix(100))

        return Chart {
            ForEach(Array(displayData.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.red.opacity(0.3), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisValueLabel()
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

struct OxygenChartView: View {
    let data: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            statsRow
            chartContent
        }
        .background(backgroundStyle)
    }

    private var headerView: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "lungs.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("OKSİJEN SİNYALİ")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Text("Kırmızı (RED) Kanal")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            if !data.isEmpty {
                Text("\(data.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var statsRow: some View {
        Group {
            if data.count > 10 {
                let displayData = Array(data.suffix(100))
                let minValue = displayData.min() ?? 0
                let maxValue = displayData.max() ?? 0
                let avgValue = displayData.reduce(0, +) / Double(displayData.count)

                HStack(spacing: 12) {
                    StatBadge(label: "Min", value: String(format: "%.0f", minValue), color: .blue)
                    StatBadge(label: "Ort", value: String(format: "%.0f", avgValue), color: .cyan)
                    StatBadge(label: "Max", value: String(format: "%.0f", maxValue), color: .orange)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var chartContent: some View {
        ZStack {
            if data.isEmpty {
                emptyStateView
            } else {
                actualChart
            }
        }
        .frame(height: 160)
        .background(chartBackground)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(.cyan.opacity(0.3))

            Text("Sinyal bekleniyor...")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var actualChart: some View {
        let displayData = Array(data.suffix(100))

        return Chart {
            ForEach(Array(displayData.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(Color.cyan)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.cyan.opacity(0.3), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisValueLabel()
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
            )
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

struct ModernMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    let note: String?

    init(
        title: String, value: String, unit: String, color: Color, icon: String, note: String? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.color = color
        self.icon = icon
        self.note = note
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            if let note = note {
                Text(note)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(color.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct PulseIndicator: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Circle()
                .stroke(color.opacity(0.4), lineWidth: 2)
                .frame(width: 10, height: 10)
                .scaleEffect(isPulsing ? 2.2 : 1)
                .opacity(isPulsing ? 0 : 0.8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

struct LargeMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    let subtitle: String?

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(color.opacity(0.8))
                    }
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(color.opacity(0.35), lineWidth: 1.5)
        )
    }
}

struct CircularCountdownTimer: View {
    let countdown: Int
    let total: Int
    let color: Color

    private var progress: Double {
        Double(total - countdown) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(countdown)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("sn")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(width: 80, height: 80)
    }
}

struct AnimatedButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .opacity(0.8)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
