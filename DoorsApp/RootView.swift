import AuthFeature
import DomainKit
import DoorsFeature
import EventsFeature
import SwiftUI

struct RootView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var coordinator = AppCoordinator()
    let featureFlags: any FeatureFlagServiceProtocol
    private let debugFeatureFlags: LocalFeatureFlagService
    @State private var showDebugFlags = false

    init(authViewModel: AuthViewModel,
         featureFlags: any FeatureFlagServiceProtocol,
         debugFeatureFlags: LocalFeatureFlagService) {
        _authViewModel = Bindable(authViewModel)
        self.featureFlags = featureFlags
        self.debugFeatureFlags = debugFeatureFlags
    }

    var body: some View {
        if authViewModel.isAuthenticated {
            NavigationStack(path: $coordinator.navigationPath) {
                DoorsListView(onSignOut: { authViewModel.signOut() })
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button { showDebugFlags = true } label: {
                                Image(systemName: "slider.horizontal.3")
                            }
                        }
                    }
                    .navigationDestination(for: Door.self) { door in
                        DoorDetailView(door: door, featureFlags: featureFlags)
                    }
            }
            .sheet(isPresented: $showDebugFlags) {
                DebugFlagsView(service: debugFeatureFlags)
            }
        } else {
            SignInView(viewModel: authViewModel)
        }
    }
}
