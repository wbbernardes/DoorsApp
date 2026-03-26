import AuthFeature
import DomainKit
import DoorsFeature
import EventsFeature
import SwiftUI

struct RootView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var coordinator = AppCoordinator()

    var body: some View {
        if authViewModel.isAuthenticated {
            NavigationStack(path: $coordinator.navigationPath) {
                DoorsListView(onSignOut: { authViewModel.signOut() })
                    .navigationDestination(for: Door.self) { door in
                        DoorDetailView(door: door)
                    }
            }
        } else {
            SignInView(viewModel: authViewModel)
        }
    }
}
