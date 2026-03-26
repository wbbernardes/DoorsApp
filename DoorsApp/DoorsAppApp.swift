import AuthFeature
import Firebase
import SwiftUI

@main
struct DoorsAppApp: App {
    @State private var authViewModel = AuthViewModel()
    private let container: DependencyContainer

    init() {
        FirebaseApp.configure()
        container = DependencyContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView(authViewModel: authViewModel, featureFlags: container.featureFlags)
        }
    }
}
