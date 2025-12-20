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
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.06),
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if ble.foundDevices.isEmpty {
                    emptyState
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(Array(ble.foundDevices.enumerated()), id: \.element.id) {
                                index, device in
                                deviceRow(device)
                                    .transition(
                                        .asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .opacity
                                        )
                                    )
                                    .animation(
                                        .spring(response: 0.4, dampingFraction: 0.7).delay(
                                            Double(index) * 0.05), value: ble.foundDevices.count)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.95)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                showContent = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation {
                        showContent = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.6))
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
                    Image(
                        systemName: ble.isScanning
                            ? "stop.circle.fill" : "arrow.clockwise.circle.fill"
                    )
                    .font(.system(size: 28))
                    .foregroundColor(ble.isScanning ? .red : .cyan)
                    .rotationEffect(.degrees(ble.isScanning ? 360 : 0))
                    .animation(
                        ble.isScanning
                            ? .linear(duration: 2).repeatForever(autoreverses: false)
                            : .default,
                        value: ble.isScanning
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            if ble.isScanning {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.cyan)
                        .scaleEffect(0.8)

                    Text("Bluetooth cihazları taranıyor...")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.cyan.opacity(0.1))
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.bottom, 16)
        .background(
            Color.white.opacity(0.03)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.1), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text(ble.isScanning ? "Cihazlar Aranıyor..." : "Cihaz Bulunamadı")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(
                    ble.isScanning
                        ? "Yakındaki Bluetooth cihazları taranıyor"
                        : "Aramayı başlatmak için yenile düğmesine tıklayın"
                )
                .font(.system(size: 13, weight: .medium, design: .rounded))
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
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
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
                    .shadow(color: Color.cyan.opacity(0.3), radius: 10, y: 5)
                }
            }
        }
        .padding()
    }

    private func deviceRow(_ device: DiscoveredPeripheral) -> some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            ble.connect(to: device.peripheral)
            withAnimation {
                showContent = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
            HapticManager.shared.success()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.2), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "sensor.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.cyan)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(device.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(device.peripheral.identifier.uuidString.prefix(18) + "...")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    if let rssi = device.rssi {
                        signalStrengthIndicator(rssi.intValue)
                    }

                    if ble.isConnected && ble.targetPeripheral?.identifier == device.id {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)

                            Text("Bağlı")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
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
                        ble.isConnected && ble.targetPeripheral?.identifier == device.id
                            ? LinearGradient(
                                colors: [Color.green.opacity(0.5), Color.green.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: ble.isConnected && ble.targetPeripheral?.identifier == device.id
                    ? Color.green.opacity(0.2)
                    : Color.clear,
                radius: 8,
                y: 4
            )
        }
    }

    private func signalStrengthIndicator(_ rssi: Int) -> some View {
        let strength = rssi > -60 ? 3 : rssi > -75 ? 2 : 1
        let color = rssi > -60 ? Color.green : rssi > -75 ? Color.orange : Color.red

        return HStack(spacing: 3) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < strength ? color : Color.white.opacity(0.15))
                    .frame(width: 4, height: CGFloat((i + 1) * 5))
            }
        }
    }
}
