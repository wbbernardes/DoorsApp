import AuthFeature
import SwiftUI

@main
struct DoorsAppApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(authViewModel: authViewModel)
        }
    }
}
