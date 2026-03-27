import SwiftUI

struct DebugFlagsView: View {
    @Bindable var service: LocalFeatureFlagService

    var body: some View {
        NavigationStack {
            Form {
                Section("Feature Flags") {
                    Toggle("BLE Simulation Mode", isOn: $service.bleSimulationMode)
                    Toggle("New Door Detail UI", isOn: $service.newDoorDetailUI)
                    Toggle("E2E Encryption", isOn: $service.e2eEncryption)
                }
                Section {
                    Text("Alterações são aplicadas imediatamente e persistidas entre sessões.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Debug — Feature Flags")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
