//
//  DevicePickerView.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 18.12.2025.
//

import CoreBluetooth
import SwiftUI

struct DevicePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ble: BLEManager
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.06)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if ble.foundDevices.isEmpty {
                    emptyState
                        .frame(maxHeight: .infinity)
                } else {
                    deviceList
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                showContent = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
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
                    Text("CİHAZ SEÇİMİ")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(ble.foundDevices.count) cihaz bulundu")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)

                Button(action: {
                    HapticManager.shared.selection()
                    if ble.isScanning {
                        ble.stopScanning()
                    } else {
                        ble.startScanning()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                ble.isScanning ? Color.red.opacity(0.15) : Color.cyan.opacity(0.15)
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: ble.isScanning ? "stop.fill" : "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ble.isScanning ? .red : .cyan)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            if ble.isScanning {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.cyan)
                        .scaleEffect(0.8)

                    Text("Cihazlar taranıyor...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.cyan.opacity(0.1))
                )
            }
        }
        .padding(.bottom, 16)
        .background(Color.white.opacity(0.02))
    }

    private var deviceList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 12) {
                ForEach(ble.foundDevices, id: \.id) { device in
                    DeviceRow(
                        device: device,
                        isConnected: ble.isConnected
                            && ble.targetPeripheral?.identifier == device.id
                    ) {
                        HapticManager.shared.impact(.medium)
                        ble.connect(to: device.peripheral)
                        dismiss()
                        HapticManager.shared.success()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var emptyState: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(
                    systemName: ble.isScanning
                        ? "antenna.radiowaves.left.and.right"
                        : "antenna.radiowaves.left.and.right.slash"
                )
                .font(.system(size: 48))
                .foregroundColor(ble.isScanning ? .cyan : .gray)
            }

            VStack(spacing: 8) {
                Text(ble.isScanning ? "Cihazlar Aranıyor..." : "Cihaz Bulunamadı")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(
                    ble.isScanning
                        ? "Yakındaki Bluetooth cihazları taranıyor"
                        : "Aramayı başlatmak için butona tıklayın"
                )
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }

            if !ble.isScanning {
                Button(action: {
                    HapticManager.shared.impact(.medium)
                    ble.startScanning()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Aramayı Başlat")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
            }
        }
        .padding()
    }
}

struct DeviceRow: View {
    let device: DiscoveredPeripheral
    let isConnected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isConnected ? Color.green.opacity(0.15) : Color.cyan.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: "sensor.fill")
                        .font(.system(size: 22))
                        .foregroundColor(isConnected ? .green : .cyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(String(device.peripheral.identifier.uuidString.prefix(18)) + "...")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    if let rssi = device.rssi {
                        SignalStrengthView(rssi: rssi.intValue)
                    }

                    if isConnected {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)

                            Text("Bağlı")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                        )
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isConnected ? Color.green.opacity(0.4) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(DeviceButtonStyle())
    }
}

struct DeviceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SignalStrengthView: View {
    let rssi: Int

    private var strength: Int {
        rssi > -60 ? 3 : rssi > -75 ? 2 : 1
    }

    private var color: Color {
        rssi > -60 ? .green : rssi > -75 ? .orange : .red
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < strength ? color : Color.white.opacity(0.15))
                    .frame(width: 4, height: CGFloat((i + 1) * 5))
            }
        }
    }
}
