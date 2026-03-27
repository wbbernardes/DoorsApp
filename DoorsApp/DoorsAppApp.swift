import AuthFeature
import SwiftUI

@main
struct DoorsAppApp: App {
    @State private var authViewModel = AuthViewModel()
    private let container: DependencyContainer

    init() {
        container = DependencyContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView(authViewModel: authViewModel,
                     featureFlags: container.featureFlags,
                     debugFeatureFlags: container.localFeatureFlags)
        }
    }
}
