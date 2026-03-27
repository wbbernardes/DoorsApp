import CoreNetwork
import DomainKit

/// Composition root — instantiates and owns all concrete service implementations.
/// Inject via initializer or SwiftUI environment into view models that need them.
final class DependencyContainer {
    let featureFlags: any FeatureFlagServiceProtocol
    let localFeatureFlags: LocalFeatureFlagService

    init() {
        let local = LocalFeatureFlagService()
        featureFlags = local
        localFeatureFlags = local
        APIClient.shared.encryptionEnabled = local.e2eEncryption
    }
}
