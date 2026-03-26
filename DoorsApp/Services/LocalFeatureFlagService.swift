#if DEBUG
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

        init() {
            let store = UserDefaults.standard
            bleSimulationMode = store.object(forKey: FeatureFlag.bleSimulationMode.rawValue) as? Bool ?? true
            newDoorDetailUI = store.object(forKey: FeatureFlag.newDoorDetailUI.rawValue) as? Bool ?? false
        }

        func isEnabled(_ flag: FeatureFlag) async -> Bool {
            switch flag {
            case .bleSimulationMode: return bleSimulationMode
            case .newDoorDetailUI: return newDoorDetailUI
            }
        }

        func stringValue(for _: FeatureFlag) async -> String {
            return ""
        }
    }
#endif
