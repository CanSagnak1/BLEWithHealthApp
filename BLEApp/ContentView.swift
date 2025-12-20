//
//  ContentView.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 18.12.2025.
//

import Charts
import Combine
import CoreBluetooth
import SwiftUI

struct ContentView: View {
    @StateObject var ble = BLEManager()
    @State var showDevices = false
    @State var isMeasuring = false
    @State var countdown = 30
    @State var result: AnalysisResult?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.06),
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 8)

                    if isMeasuring {
                        liveMetricsDashboard
                            .padding(.horizontal)
                    }

                    HeartRateChartView(data: ble.irData)
                        .padding(.horizontal)

                    OxygenChartView(data: ble.redData)
                        .padding(.horizontal)

                    if isMeasuring {
                        progressSection
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 20)

                    controlPanel
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showDevices) {
            DevicePickerView(ble: ble)
        }
        .sheet(item: $result) { r in
            ReportView(result: r)
        }
        .onReceive(timer) { _ in
            if isMeasuring && countdown > 0 {
                countdown -= 1
            } else if isMeasuring && countdown == 0 {
                stopMeasurement()
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg.rectangle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("BİYOSİNYAL ANALİZ")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("Sağlık İzleme Sistemi")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                connectionStatusView
            }

            if ble.isConnected {
                deviceInfoCard
            }
        }
    }

    private var connectionStatusView: some View {
        Button(action: {
            HapticManager.shared.selection()
            showDevices = true
        }) {
            HStack(spacing: 10) {
                if ble.isConnected {
                    PulseIndicator(color: .green)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(ble.isConnected ? "BAĞLI" : "BAĞLI DEĞİL")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(ble.isConnected ? .green : .gray)

                    if ble.isConnected {
                        Text("Aktif")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        ble.isConnected ? Color.green.opacity(0.3) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
    }

    private var deviceInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sensor.fill")
                .font(.system(size: 18))
                .foregroundColor(.cyan)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(ble.targetPeripheral?.name ?? "Bilinmeyen Cihaz")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(ble.irData.count + ble.redData.count) toplam veri noktası")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
        )
    }

    private var liveMetricsDashboard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))

                Text("CANLI METRİKLER")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)

                    Text("CANLI")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.15))
                )
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                let currentRes = SignalProcessor.process(
                    times: ble.timeData, reds: ble.redData, irs: ble.irData)

                ModernMetricCard(
                    title: "Nabız",
                    value: currentRes.bpm != nil ? "\(currentRes.bpm!)" : "---",
                    unit: "BPM",
                    color: .red,
                    icon: "heart.fill",
                    note: currentRes.isSaturated
                        ? "Doygunluk"
                        : (currentRes.bpm != nil
                            ? "Ölçülüyor" : (ble.irData.count > 10 ? "Analiz..." : "Bekleniyor"))
                )

                ModernMetricCard(
                    title: "Oksijen",
                    value: currentRes.spo2 != nil ? "\(currentRes.spo2!)" : "---",
                    unit: "%",
                    color: .cyan,
                    icon: "lungs.fill",
                    note: currentRes.spo2 != nil ? "Stabil" : "Hesaplanıyor"
                )

                ModernMetricCard(
                    title: "Perfüzyon",
                    value: String(format: "%.1f", currentRes.pi),
                    unit: "%",
                    color: .orange,
                    icon: "drop.fill",
                    note: currentRes.pi < 0.2 ? "Zayıf" : nil
                )

                ModernMetricCard(
                    title: "Süre",
                    value: "\(countdown)",
                    unit: "sn",
                    color: .purple,
                    icon: "clock.fill",
                    note: countdown < 10 ? "Bitiyor" : nil
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.blue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ÖLÇÜM İLERLEMESİ")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Text("\(Int((30 - countdown) * 100 / 30))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(30 - countdown) / 30)
                        .animation(.linear(duration: 1), value: countdown)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
    }

    private var controlPanel: some View {
        VStack(spacing: 16) {
            if isMeasuring {
                stopButton
            } else {
                startButton
            }

            HStack(spacing: 6) {
                Image(systemName: ble.isConnected ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(ble.isConnected ? .green : .orange)

                Text(
                    ble.isConnected
                        ? "Sistem hazır • \(ble.irData.count) IR, \(ble.redData.count) Red örnek"
                        : "Ölçüm için lütfen cihaz bağlayın"
                )
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.03))
            )
        }
    }

    private var startButton: some View {
        Button(action: startMeasurement) {
            HStack(spacing: 14) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 26))

                VStack(alignment: .leading, spacing: 2) {
                    Text("ÖLÇÜMÜ BAŞLAT")
                        .font(.system(size: 16, weight: .bold, design: .rounded))

                    Text("30 saniyelik ölçüm")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .opacity(0.8)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: ble.isConnected
                                ? [Color.green, Color.green.opacity(0.8)]
                                : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: ble.isConnected ? Color.green.opacity(0.3) : Color.clear,
                radius: 12,
                y: 6
            )
        }
        .disabled(!ble.isConnected)
    }

    private var stopButton: some View {
        Button(action: stopMeasurement) {
            HStack(spacing: 14) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 26))

                VStack(alignment: .leading, spacing: 2) {
                    Text("ÖLÇÜMÜ DURDUR")
                        .font(.system(size: 16, weight: .bold, design: .rounded))

                    Text("Verileri analiz et")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .opacity(0.8)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.red.opacity(0.3), radius: 12, y: 6)
        }
    }

    private func calculatePI() -> String {
        let res = SignalProcessor.process(times: ble.timeData, reds: ble.redData, irs: ble.irData)
        return String(format: "%.1f", res.pi)
    }

    private func startMeasurement() {
        HapticManager.shared.impact(.medium)
        ble.timeData.removeAll()
        ble.redData.removeAll()
        ble.irData.removeAll()
        ble.clearBuffer()
        ble.sendCommand("START")
        isMeasuring = true
        countdown = 30
        HapticManager.shared.success()
    }

    private func stopMeasurement() {
        HapticManager.shared.impact(.medium)
        ble.sendCommand("STOP")
        isMeasuring = false
        result = SignalProcessor.process(times: ble.timeData, reds: ble.redData, irs: ble.irData)
        HapticManager.shared.success()
    }
}
