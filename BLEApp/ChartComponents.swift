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
    @State private var animateChart = false

    var body: some View {
        chartContainer
            .opacity(animateChart ? 1 : 0)
            .scaleEffect(animateChart ? 1 : 0.95)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    animateChart = true
                }
            }
    }

    private var chartContainer: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            chartContent
        }
        .background(backgroundStyle)
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)

            Text("NABIZ SİNYALİ (IR)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            if !data.isEmpty {
                Text("\(data.count) örnek")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
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
        VStack(spacing: 8) {
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
        Chart {
            ForEach(Array(data.suffix(150).enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.red, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Color.red.opacity(0.4),
                            Color.pink.opacity(0.2),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        .linearGradient(
                            colors: [.red.opacity(0.3), .pink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

struct OxygenChartView: View {
    let data: [Double]
    @State private var animateChart = false

    var body: some View {
        chartContainer
            .opacity(animateChart ? 1 : 0)
            .scaleEffect(animateChart ? 1 : 0.95)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                    animateChart = true
                }
            }
    }

    private var chartContainer: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            chartContent
        }
        .background(backgroundStyle)
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.cyan)

            Text("OKSİJEN SİNYALİ (RED)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            if !data.isEmpty {
                Text("\(data.count) örnek")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
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
        VStack(spacing: 8) {
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
        Chart {
            ForEach(Array(data.suffix(150).enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Color.cyan.opacity(0.4),
                            Color.blue.opacity(0.2),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        .linearGradient(
                            colors: [.cyan.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
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

    @State private var animateValue = false

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
        cardContent
            .scaleEffect(animateValue ? 1 : 0.95)
            .opacity(animateValue ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateValue = true
                }
            }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader
            valueDisplay
            noteDisplay
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
    }

    private var cardHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
        }
    }

    private var valueDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())

            Text(unit)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    @ViewBuilder
    private var noteDisplay: some View {
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

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        .linearGradient(
                            colors: [color.opacity(0.4), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct PulseIndicator: View {
    @State private var isPulsing = false
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Circle()
                .stroke(color.opacity(0.5), lineWidth: 2)
                .frame(width: 10, height: 10)
                .scaleEffect(isPulsing ? 2.5 : 1)
                .opacity(isPulsing ? 0 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}
