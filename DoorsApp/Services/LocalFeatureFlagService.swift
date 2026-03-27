import CoreNetwork
import DomainKit
import Foundation

@Observable
@MainActor
final class LocalFeatureFlagService: FeatureFlagServiceProtocol {
    var bleSimulationMode: Bool {
        didSet { UserDefaults.standard.set(bleSimulationMode, forKey: FeatureFlag.bleSimulationMode.rawValue) }
    }

    var newDoorDetailUI: Bool {
        didSet { UserDefaults.standard.set(newDoorDetailUI, forKey: FeatureFlag.newDoorDetailUI.rawValue) }
    }

    var e2eEncryption: Bool {
        didSet {
            UserDefaults.standard.set(e2eEncryption, forKey: FeatureFlag.e2eEncryption.rawValue)
            APIClient.shared.encryptionEnabled = e2eEncryption
        }
    }

    init() {
        let store = UserDefaults.standard
        bleSimulationMode = store.object(forKey: FeatureFlag.bleSimulationMode.rawValue) as? Bool ?? true
        newDoorDetailUI = store.object(forKey: FeatureFlag.newDoorDetailUI.rawValue) as? Bool ?? false
        e2eEncryption = store.object(forKey: FeatureFlag.e2eEncryption.rawValue) as? Bool ?? false
    }

    nonisolated func isEnabled(_ flag: FeatureFlag) async -> Bool {
        await MainActor.run {
            switch flag {
            case .bleSimulationMode: return bleSimulationMode
            case .newDoorDetailUI: return newDoorDetailUI
            case .e2eEncryption: return e2eEncryption
            }
        }
    }

    nonisolated func stringValue(for _: FeatureFlag) async -> String {
        ""
    }
}
