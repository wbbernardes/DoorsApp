import DomainKit

/// Composition root — instantiates and owns all concrete service implementations.
/// Inject via initializer or SwiftUI environment into view models that need them.
final class DependencyContainer {
    let featureFlags: any FeatureFlagServiceProtocol
    #if DEBUG
        let localFeatureFlags: LocalFeatureFlagService
    #endif

    init() {
        #if DEBUG
            let local = LocalFeatureFlagService()
            featureFlags = local
            localFeatureFlags = local
        #else
            featureFlags = FirebaseFeatureFlagService()
        #endif
    }
}
