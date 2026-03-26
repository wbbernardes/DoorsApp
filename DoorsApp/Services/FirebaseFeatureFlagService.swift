import DomainKit
@preconcurrency import FirebaseRemoteConfig

final class FirebaseFeatureFlagService: FeatureFlagServiceProtocol {
    private let remoteConfig = RemoteConfig.remoteConfig()

    init() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(Self.defaults)
        Task { try? await remoteConfig.fetchAndActivate() }
    }

    func isEnabled(_ flag: FeatureFlag) async -> Bool {
        remoteConfig[flag.rawValue].boolValue
    }

    func stringValue(for flag: FeatureFlag) async -> String {
        remoteConfig[flag.rawValue].stringValue
    }
}

private extension FirebaseFeatureFlagService {
    static var defaults: [String: NSObject] {
        [
            FeatureFlag.bleSimulationMode.rawValue: true as NSObject,
            FeatureFlag.newDoorDetailUI.rawValue: false as NSObject,
        ]
    }
}
