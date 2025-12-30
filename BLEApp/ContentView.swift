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
            Color(red: 0.03, green: 0.03, blue: 0.06)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    if isMeasuring {
                        measurementDashboard
                            .padding(.horizontal, 20)
                    }

                    HeartRateChartView(data: ble.irData)
                        .padding(.horizontal, 16)

                    OxygenChartView(data: ble.redData)
                        .padding(.horizontal, 16)

                    controlPanel
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
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
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cyan.opacity(0.2))
                                .frame(width: 42, height: 42)

                            Image(systemName: "waveform.path.ecg.rectangle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.cyan)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("BİYOSİNYAL")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.white)

                            Text("Sağlık İzleme Sistemi")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()

                connectionBadge
            }

            if ble.isConnected {
                connectedDeviceCard
            }
        }
    }

    private var connectionBadge: some View {
        Button(action: {
            HapticManager.shared.selection()
            showDevices = true
        }) {
            HStack(spacing: 8) {
                if ble.isConnected {
                    PulseIndicator(color: .green)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(ble.isConnected ? "BAĞLI" : "BAĞLI DEĞİL")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(ble.isConnected ? .green : .gray)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        ble.isConnected ? Color.green.opacity(0.3) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
    }

    private var connectedDeviceCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "sensor.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(ble.targetPeripheral?.name ?? "Bilinmeyen Cihaz")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 5, height: 5)
                        Text("\(ble.irData.count) IR")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.cyan.opacity(0.8))
                            .frame(width: 5, height: 5)
                        Text("\(ble.redData.count) RED")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.green)
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

    private var measurementDashboard: some View {
        let currentRes = SignalProcessor.process(
            times: ble.timeData, reds: ble.redData, irs: ble.irData)

        return VStack(spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)

                    Text("CANLI ÖLÇÜM")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Text("AKTİF")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
            }

            HStack(spacing: 14) {
                LargeMetricCard(
                    title: "Nabız",
                    value: currentRes.bpm != nil ? "\(currentRes.bpm!)" : "---",
                    unit: "BPM",
                    color: .red,
                    icon: "heart.fill",
                    subtitle: currentRes.isSaturated
                        ? "Doygunluk"
                        : (currentRes.bpm != nil
                            ? "Ölçülüyor" : (ble.irData.count > 10 ? "Analiz..." : "Bekleniyor"))
                )

                CircularCountdownTimer(
                    countdown: countdown,
                    total: 30,
                    color: .cyan
                )
            }

            HStack(spacing: 10) {
                SmallMetricCard(
                    title: "SpO₂",
                    value: currentRes.spo2 != nil ? "\(currentRes.spo2!)" : "---",
                    unit: "%",
                    color: .cyan,
                    icon: "lungs.fill"
                )

                SmallMetricCard(
                    title: "PI",
                    value: String(format: "%.1f", currentRes.pi),
                    unit: "%",
                    color: .orange,
                    icon: "drop.fill"
                )

                SmallMetricCard(
                    title: "Kalite",
                    value: currentRes.pi > 0.5 ? "İyi" : "Düşük",
                    unit: "",
                    color: currentRes.pi > 0.5 ? .green : .yellow,
                    icon: "chart.bar.fill"
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    private var controlPanel: some View {
        VStack(spacing: 14) {
            if isMeasuring {
                AnimatedButton(
                    title: "ÖLÇÜMÜ DURDUR",
                    subtitle: "Verileri analiz et",
                    icon: "stop.circle.fill",
                    colors: [.red, .red.opacity(0.7)],
                    action: stopMeasurement
                )
            } else {
                AnimatedButton(
                    title: "ÖLÇÜMÜ BAŞLAT",
                    subtitle: "30 saniyelik ölçüm",
                    icon: "play.circle.fill",
                    colors: ble.isConnected
                        ? [.green, .green.opacity(0.7)]
                        : [.gray.opacity(0.3), .gray.opacity(0.2)],
                    action: startMeasurement
                )
                .disabled(!ble.isConnected)
                .opacity(ble.isConnected ? 1 : 0.6)
            }

            statusIndicator
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: ble.isConnected ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(ble.isConnected ? .green : .orange)

            Text(
                ble.isConnected
                    ? "Sistem hazır • Ölçüm için butona dokunun"
                    : "Ölçüm için lütfen bir cihaz bağlayın"
            )
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.03))
        )
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

struct SmallMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
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
