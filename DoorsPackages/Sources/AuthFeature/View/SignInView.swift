//
//  SignInView.swift
//

import DesignSystemKit
import SwiftUI

public struct SignInView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var showSignUp = false

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                background

                VStack(spacing: Layout.outerSpacing) {
                    Spacer()

                    Text("auth.app_title", bundle: .module)
                        .font(.largeTitle.bold())

                    formCard

                    PrimaryActionButton(
                        String(localized: "auth.sign_in", bundle: .module),
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isSignInFormValid,
                        action: viewModel.onSignInTap
                    )

                    Button {
                        showSignUp = true
                    } label: {
                        Text("auth.sign_up_prompt", bundle: .module)
                            .foregroundStyle(.primary)
                    }
                    .font(.footnote)

                    Spacer()
                }
                .padding(.horizontal, Layout.horizontalPadding)
            }
            .onAppear { viewModel.clearError() }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(viewModel: viewModel)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(Layout.gradientStartOpacity), Color(.systemBackground)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var formCard: some View {
        VStack(spacing: Layout.fieldSpacing) {
            glassField {
                TextField(String(localized: "auth.email", bundle: .module), text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }

            glassField {
                SecureField(String(localized: "auth.password", bundle: .module), text: $viewModel.password)
                    .textContentType(.password)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Layout.cardPadding)
        .glassEffect(in: .rect(cornerRadius: Layout.cardCornerRadius))
    }

    private func glassField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, Layout.fieldPaddingH)
            .padding(.vertical, Layout.fieldPaddingV)
            .frame(height: Layout.fieldHeight)
            .glassEffect(in: .rect(cornerRadius: Layout.fieldCornerRadius))
    }
}

// MARK: - Layout

extension SignInView {
    enum Layout {
        static let outerSpacing: CGFloat = 24
        static let fieldSpacing: CGFloat = 12
        static let fieldHeight: CGFloat = 44
        static let fieldPaddingH: CGFloat = 12
        static let fieldPaddingV: CGFloat = 8
        static let fieldCornerRadius: CGFloat = 10
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 20
        static let horizontalPadding: CGFloat = 24
        static let gradientStartOpacity: Double = 0.15
    }
}

// MARK: - Preview

#Preview("Sign In") {
    SignInView(viewModel: AuthViewModel())
}
