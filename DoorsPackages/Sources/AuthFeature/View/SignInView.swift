//
//  SignInView.swift
//

import SwiftUI

public struct SignInView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var showSignUp = false

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: Layout.outerSpacing) {
                Spacer()

                Text("auth.app_title", bundle: .module)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)

                VStack(spacing: Layout.fieldSpacing) {
                    TextField(String(localized: "auth.email", bundle: .module), text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .foregroundStyle(.primary)
                        .frame(height: Layout.fieldHeight)

                    SecureField(String(localized: "auth.password", bundle: .module), text: $viewModel.password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                        .foregroundStyle(.primary)
                        .frame(height: Layout.fieldHeight)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                let isDisabled = viewModel.isLoading || !viewModel.isSignInFormValid
                Button(action: viewModel.onSignInTap) {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("auth.sign_in", bundle: .module)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.fieldHeight)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDisabled)
                .opacity(isDisabled ? Layout.disabledOpacity : 1.0)

                Button {
                    showSignUp = true
                } label: {
                    Text("auth.sign_up_prompt", bundle: .module)
                        .foregroundStyle(.primary)
                }
                .font(.footnote)

                Spacer()
            }
            .padding(Layout.padding)
            .onAppear { viewModel.clearError() }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Layout

extension SignInView {
    enum Layout {
        static let outerSpacing: CGFloat = 24
        static let fieldSpacing: CGFloat = 16
        static let fieldHeight: CGFloat = 40
        static let padding: CGFloat = 16
        static let disabledOpacity: Double = 0.4
    }
}

// MARK: - Preview

#Preview("Sign In") {
    SignInView(viewModel: AuthViewModel())
}
