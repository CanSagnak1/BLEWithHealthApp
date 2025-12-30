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
    @Published var dataRate: Int = 0

    var centralManager: CBCentralManager!
    var targetPeripheral: CBPeripheral?
    var writeCharacteristic: CBCharacteristic?
    private var rxBuffer = ""

    // Ring buffer settings
    private let maxBufferSize = 500

    // Background processing
    private let processingQueue = DispatchQueue(label: "com.bleapp.processing", qos: .userInitiated)
    private var pendingDataBatch: [(time: Double, red: Double, ir: Double)] = []
    private let batchSize = 5

    // Data rate calculation
    private var sampleCount = 0
    private var lastRateUpdate = Date()

    // Valid data range
    private let minValidValue: Double = 5000
    private let maxValidValue: Double = 300000

    let serviceUUID = CBUUID(string: "FFE0")
    let charUUID = CBUUID(string: "FFE1")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startDataRateTimer()
    }

    private func startDataRateTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.dataRate = self.sampleCount
                self.sampleCount = 0
            }
        }
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
        pendingDataBatch.removeAll()
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
        peripheral.discoverServices([serviceUUID])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendCommand("C")
        }
    }

    func centralManager(
        _ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?
    ) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }

        if let service = services.first(where: { $0.uuid == serviceUUID }) ?? services.first {
            peripheral.discoverCharacteristics([charUUID], for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?
    ) {
        guard error == nil else { return }

        for char in service.characteristics ?? [] {
            if char.uuid == charUUID {
                self.writeCharacteristic = char

                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char)
                }
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil,
            let data = characteristic.value,
            let str = String(data: data, encoding: .utf8)
        else { return }

        // Process on background queue
        processingQueue.async { [weak self] in
            self?.processIncomingData(str)
        }
    }

    private func processIncomingData(_ str: String) {
        rxBuffer += str

        let lines = rxBuffer.components(separatedBy: .newlines)

        for i in 0..<(lines.count - 1) {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)

            guard !line.isEmpty else { continue }

            let parts = line.components(separatedBy: ",")

            if parts.count == 4 && parts[0] == "RAW" {
                if let t = Double(parts[1]),
                    let r = Double(parts[2]),
                    let i = Double(parts[3])
                {

                    // Validate data range
                    guard isValidReading(red: r, ir: i) else { continue }

                    pendingDataBatch.append((time: t, red: r, ir: i))
                    sampleCount += 1

                    // Batch update when we have enough samples
                    if pendingDataBatch.count >= batchSize {
                        let batch = pendingDataBatch
                        pendingDataBatch.removeAll()

                        DispatchQueue.main.async { [weak self] in
                            self?.applyBatchUpdate(batch)
                        }
                    }
                }
            }
        }

        rxBuffer = lines.last ?? ""
    }

    private func isValidReading(red: Double, ir: Double) -> Bool {
        // Check if values are within valid range
        let redValid = red >= minValidValue && red <= maxValidValue
        let irValid = ir >= minValidValue && ir <= maxValidValue

        // Check for sudden spikes (artifact detection)
        if !irData.isEmpty {
            let lastIr = irData.last!
            let changeRatio = abs(ir - lastIr) / max(lastIr, 1)
            if changeRatio > 0.5 {  // More than 50% sudden change
                return false
            }
        }

        return redValid && irValid
    }

    private func applyBatchUpdate(_ batch: [(time: Double, red: Double, ir: Double)]) {
        for item in batch {
            timeData.append(item.time)
            redData.append(item.red)
            irData.append(item.ir)
        }

        currentIR = batch.last?.ir ?? currentIR

        // Apply ring buffer limit
        trimBuffers()
    }

    private func trimBuffers() {
        if timeData.count > maxBufferSize {
            let excess = timeData.count - maxBufferSize
            timeData.removeFirst(excess)
            redData.removeFirst(excess)
            irData.removeFirst(excess)
        }
    }

    func sendCommand(_ command: String) {
        guard let char = writeCharacteristic,
            let data = (command + "\n").data(using: .utf8)
        else { return }
        targetPeripheral?.writeValue(data, for: char, type: .withoutResponse)
    }
}
