import Foundation
import UIKit

/// A stable per-install identifier sent to the AI-generation backend so it
/// can enforce the free-tier quota. Prefers `identifierForVendor`; falls
/// back to a UUID persisted in `UserDefaults` on the rare device where the
/// vendor identifier isn't available yet (e.g. very early app launch).
enum DeviceIdentity {
    private static let fallbackKey = "ks.fallbackDeviceId"

    static var current: String {
        if let vendorID = UIDevice.current.identifierForVendor?.uuidString, !vendorID.isEmpty {
            return vendorID
        }
        if let saved = UserDefaults.standard.string(forKey: fallbackKey) {
            return saved
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: fallbackKey)
        return generated
    }
}
