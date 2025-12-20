import Foundation
import CoreBluetooth

// A lightweight wrapper used to display and identify discovered peripherals in SwiftUI lists.
struct DiscoveredPeripheral: Identifiable, Hashable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
    let rssi: NSNumber?

    init(peripheral: CBPeripheral, rssi: NSNumber?) {
        self.id = peripheral.identifier
        self.name = peripheral.name ?? "Unknown"
        self.peripheral = peripheral
        self.rssi = rssi
    }
}
