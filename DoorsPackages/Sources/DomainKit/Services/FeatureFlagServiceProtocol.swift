public protocol FeatureFlagServiceProtocol: Sendable {
    func isEnabled(_ flag: FeatureFlag) async -> Bool
    func stringValue(for flag: FeatureFlag) async -> String
}

public enum FeatureFlag: String, Sendable, CaseIterable {
    case bleSimulationMode = "ble_simulation_mode"
    case newDoorDetailUI = "new_door_detail_ui"
}
