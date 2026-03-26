import AuthFeature
import DomainKit
import DoorsFeature
import EventsFeature
import SwiftUI

struct RootView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var coordinator = AppCoordinator()
    let featureFlags: any FeatureFlagServiceProtocol
    #if DEBUG
        private let debugFeatureFlags: LocalFeatureFlagService
        @State private var showDebugFlags = false
    #endif

    #if DEBUG
        init(authViewModel: AuthViewModel,
             featureFlags: any FeatureFlagServiceProtocol,
             debugFeatureFlags: LocalFeatureFlagService) {
            _authViewModel = Bindable(authViewModel)
            self.featureFlags = featureFlags
            self.debugFeatureFlags = debugFeatureFlags
        }
    #else
        init(authViewModel: AuthViewModel, featureFlags: any FeatureFlagServiceProtocol) {
            _authViewModel = Bindable(authViewModel)
            self.featureFlags = featureFlags
        }
    #endif

    var body: some View {
        if authViewModel.isAuthenticated {
            NavigationStack(path: $coordinator.navigationPath) {
                DoorsListView(onSignOut: { authViewModel.signOut() })
                    .toolbar {
                        #if DEBUG
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button { showDebugFlags = true } label: {
                                    Image(systemName: "slider.horizontal.3")
                                }
                            }
                        #endif
                    }
                    .navigationDestination(for: Door.self) { door in
                        DoorDetailView(door: door, featureFlags: featureFlags)
                    }
            }
            #if DEBUG
            .sheet(isPresented: $showDebugFlags) {
                    DebugFlagsView(service: debugFeatureFlags)
                }
            #endif
        } else {
            SignInView(viewModel: authViewModel)
        }
    }
}
