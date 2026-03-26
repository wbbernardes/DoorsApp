import AuthFeature
import Firebase
import SwiftUI

@main
struct DoorsAppApp: App {
    @State private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView(authViewModel: authViewModel)
        }
    }
}
