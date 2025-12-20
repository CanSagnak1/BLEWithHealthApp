//
//  HapticManager.swift
//  BLEApp
//
//  Created by Celal Can Sağnak on 18.12.2025.
//

import UIKit

class HapticManager {
    static let shared = HapticManager()

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            light.impactOccurred()
        case .medium:
            medium.impactOccurred()
        case .heavy:
            heavy.impactOccurred()
        case .soft, .rigid:
            medium.impactOccurred()
        @unknown default:
            medium.impactOccurred()
        }
    }

    func selection() {
        selectionGenerator.selectionChanged()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
    }

    func success() {
        notification.notificationOccurred(.success)
    }

    func warning() {
        notification.notificationOccurred(.warning)
    }

    func error() {
        notification.notificationOccurred(.error)
    }
}
