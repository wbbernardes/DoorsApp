import AuthFeature
import DoorsFeature
import SwiftUI

struct RootView: View {
    @Bindable var authViewModel: AuthViewModel

    var body: some View {
        if authViewModel.isAuthenticated {
            DoorsListView {
                authViewModel.signOut()
            }
        } else {
            SignInView(viewModel: authViewModel)
        }
    }
}
