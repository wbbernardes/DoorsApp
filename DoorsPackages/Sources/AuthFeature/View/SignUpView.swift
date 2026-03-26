//
//  SignUpView.swift
//

import SwiftUI

struct SignUpView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.outerSpacing) {
                Text("auth.sign_up", bundle: .module)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: Layout.fieldSpacing) {
                    TextField(String(localized: "auth.first_name", bundle: .module), text: $viewModel.firstName)
                        .textContentType(.givenName)
                        .textFieldStyle(.roundedBorder)
                        .foregroundStyle(.primary)
                        .frame(height: Layout.fieldHeight)

                    TextField(String(localized: "auth.last_name", bundle: .module), text: $viewModel.lastName)
                        .textContentType(.familyName)
                        .textFieldStyle(.roundedBorder)
                        .foregroundStyle(.primary)
                        .frame(height: Layout.fieldHeight)

                    TextField(String(localized: "auth.email", bundle: .module), text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .foregroundStyle(.primary)
                        .frame(height: Layout.fieldHeight)

                    SecureField(String(localized: "auth.password", bundle: .module), text: $viewModel.password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)
                        .foregroundStyle(.primary)
                        .frame(height: Layout.fieldHeight)

                    Text("auth.password_hint", bundle: .module)
                        .font(.caption2)
                        .foregroundStyle(.primary.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                let isDisabled = viewModel.isLoading || !viewModel.isSignUpFormValid
                Button(action: viewModel.onSignUpTap) {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("auth.sign_up", bundle: .module)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.fieldHeight)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDisabled)
                .opacity(isDisabled ? Layout.disabledOpacity : 1.0)

                Button {
                    dismiss()
                } label: {
                    Text("auth.sign_in_prompt", bundle: .module)
                        .foregroundStyle(.primary)
                }
                .font(.footnote)
            }
            .padding(Layout.padding)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.clearError() }
    }
}

// MARK: - Layout

extension SignUpView {
    enum Layout {
        static let outerSpacing: CGFloat = 24
        static let fieldSpacing: CGFloat = 16
        static let fieldHeight: CGFloat = 40
        static let padding: CGFloat = 16
        static let disabledOpacity: Double = 0.4
    }
}

// MARK: - Preview

#Preview("Sign Up") {
    NavigationStack {
        SignUpView(viewModel: AuthViewModel())
    }
}
