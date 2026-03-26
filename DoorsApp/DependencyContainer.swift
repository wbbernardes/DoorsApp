import DomainKit

/// Composition root — instantiates and owns all concrete service implementations.
/// Inject via initializer or SwiftUI environment into view models that need them.
final class DependencyContainer {
    let featureFlags: any FeatureFlagServiceProtocol

    init() {
        featureFlags = FirebaseFeatureFlagService()
    }
}
