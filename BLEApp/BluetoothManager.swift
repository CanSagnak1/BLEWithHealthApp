//
//  BluetoothManager.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 18.12.2025.
//

import Combine
import CoreBluetooth
import Foundation

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isConnected = false
    @Published var foundDevices: [DiscoveredPeripheral] = []
    @Published var irData: [Double] = []
    @Published var redData: [Double] = []
    @Published var timeData: [Double] = []
    @Published var currentIR: Double = 0
    @Published var isScanning = false

    var centralManager: CBCentralManager!
    var targetPeripheral: CBPeripheral?
    var writeCharacteristic: CBCharacteristic?
    private var rxBuffer = ""

    let serviceUUID = CBUUID(string: "FFE0")
    let charUUID = CBUUID(string: "FFE1")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        if centralManager.state == .poweredOn {
            isScanning = true
            foundDevices.removeAll()
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }

    func connect(to peripheral: CBPeripheral) {
        targetPeripheral = peripheral
        targetPeripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func clearBuffer() {
        rxBuffer = ""
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        }
    }

    func centralManager(
        _ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any], rssi RSSI: NSNumber
    ) {
        if !foundDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            foundDevices.append(DiscoveredPeripheral(peripheral: peripheral, rssi: RSSI))
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        print("✅ Connected to device: \(peripheral.name ?? "Unknown")")
        peripheral.discoverServices([serviceUUID])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("📤 Sending connection command 'C'")
            self.sendCommand("C")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            print("❌ Error discovering services: \(error?.localizedDescription ?? "Unknown")")
            return
        }

        print("🔍 Discovered \(services.count) service(s)")
        if let service = services.first(where: { $0.uuid == serviceUUID }) ?? services.first {
            print("📡 Using service: \(service.uuid)")
            peripheral.discoverCharacteristics([charUUID], for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?
    ) {
        guard error == nil else {
            print(
                "❌ Error discovering characteristics: \(error?.localizedDescription ?? "Unknown")")
            return
        }

        print("🔍 Discovered \(service.characteristics?.count ?? 0) characteristic(s)")
        for char in service.characteristics ?? [] {
            print("   - Characteristic: \(char.uuid)")
            print("     Properties: \(char.properties)")

            if char.uuid == charUUID {
                self.writeCharacteristic = char

                // Check if characteristic supports notifications
                if char.properties.contains(.notify) {
                    print("✅ Enabling notifications for characteristic \(char.uuid)")
                    peripheral.setNotifyValue(true, for: char)
                } else {
                    print(
                        "⚠️ Characteristic does not support notifications. Properties: \(char.properties)"
                    )
                }
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error = error {
            print("❌ Error updating value: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            print("⚠️ No data received from characteristic")
            return
        }

        guard let str = String(data: data, encoding: .utf8) else {
            print("⚠️ Could not decode data as UTF-8: \(data)")
            return
        }

        print(
            "📥 Received data: \(str.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r"))"
        )

        rxBuffer += str
        print(
            "🔍 Buffer now: [\(rxBuffer.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r"))] (length: \(rxBuffer.count))"
        )

        // Split by newlines (handles both \n and \r\n)
        let lines = rxBuffer.components(separatedBy: .newlines)
        print("🔍 Split into \(lines.count) parts")

        // Process all complete lines (all except the last one, which might be incomplete)
        for i in 0..<(lines.count - 1) {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)

            guard !line.isEmpty else { continue }

            print("🔍 Processing line \(i): [\(line)]")
            let parts = line.components(separatedBy: ",")
            print("🔍 Parts count: \(parts.count), Parts: \(parts)")

            if parts.count == 4 && parts[0] == "RAW" {
                if let t = Double(parts[1]), let r = Double(parts[2]), let i = Double(parts[3]) {
                    print("✅ Parsed: time=\(t)ms, red=\(Int(r)), ir=\(Int(i))")
                    DispatchQueue.main.async {
                        self.timeData.append(t)
                        self.redData.append(r)
                        self.irData.append(i)
                        self.currentIR = i
                        print(
                            "📊 Arrays updated: timeData=\(self.timeData.count), redData=\(self.redData.count), irData=\(self.irData.count)"
                        )
                    }
                } else {
                    print("⚠️ Failed to parse numeric values from: \(line)")
                }
            } else if !line.isEmpty {
                print(
                    "ℹ️ Non-data message (count=\(parts.count), first=\(parts.first ?? "nil")): \(line)"
                )
            }
        }

        // Keep the last part (might be incomplete)
        rxBuffer = lines.last ?? ""
        print(
            "🔍 Buffer remaining: [\(rxBuffer.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r"))] (length: \(rxBuffer.count))"
        )
    }

    func sendCommand(_ command: String) {
        guard let char = writeCharacteristic, let data = (command + "\n").data(using: .utf8) else {
            print("⚠️ Cannot send command: characteristic or data conversion failed")
            return
        }
        print("📤 Sending command: \(command)")
        targetPeripheral?.writeValue(data, for: char, type: .withoutResponse)
    }
}
