//
//  SignUpView.swift
//

import DesignSystemKit
import SwiftUI

struct SignUpView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: Layout.outerSpacing) {
                    Text("auth.sign_up", bundle: .module)
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    formCard

                    PrimaryActionButton(
                        String(localized: "auth.sign_up", bundle: .module),
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isSignUpFormValid,
                        action: viewModel.onSignUpTap
                    )

                    Button {
                        dismiss()
                    } label: {
                        Text("auth.sign_in_prompt", bundle: .module)
                            .foregroundStyle(.primary)
                    }
                    .font(.footnote)
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, Layout.topPadding)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.clearError() }
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
                TextField(String(localized: "auth.first_name", bundle: .module), text: $viewModel.firstName)
                    .textContentType(.givenName)
            }

            glassField {
                TextField(String(localized: "auth.last_name", bundle: .module), text: $viewModel.lastName)
                    .textContentType(.familyName)
            }

            glassField {
                TextField(String(localized: "auth.email", bundle: .module), text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }

            glassField {
                SecureField(String(localized: "auth.password", bundle: .module), text: $viewModel.password)
                    .textContentType(viewModel.isUITesting ? .oneTimeCode : .newPassword)
            }

            PasswordRequirementsView(viewModel: viewModel)

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
            .background(.thinMaterial, in: .rect(cornerRadius: Layout.fieldCornerRadius))
    }
}

// MARK: - Layout

extension SignUpView {
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
        static let topPadding: CGFloat = 16
        static let hintOpacity: Double = 0.55
        static let gradientStartOpacity: Double = 0.15
    }
}

// MARK: - PasswordRequirementsView

private struct PasswordRequirementsView: View {
    let viewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row(String(localized: "auth.password_req.length", bundle: .module),
                id: "password_req_length",
                isMet: viewModel.passwordLengthValid)
            row(String(localized: "auth.password_req.uppercase", bundle: .module),
                id: "password_req_uppercase",
                isMet: viewModel.passwordHasUppercase)
            row(String(localized: "auth.password_req.number", bundle: .module),
                id: "password_req_number",
                isMet: viewModel.passwordHasNumber)
            row(String(localized: "auth.password_req.symbol", bundle: .module),
                id: "password_req_symbol",
                isMet: viewModel.passwordHasSymbol)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ text: String, id: String, isMet: Bool) -> some View {
        let isEmpty = viewModel.password.isEmpty
        let color: Color = isEmpty ? .secondary.opacity(0.55) : (isMet ? .green : .red)
        let icon = isEmpty ? "circle" : (isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
        let state = isEmpty ? "neutral" : (isMet ? "met" : "unmet")

        return HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption2)
        .foregroundStyle(color)
        .animation(.easeInOut(duration: 0.2), value: isMet)
        .animation(.easeInOut(duration: 0.2), value: isEmpty)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(id)
        .accessibilityValue(state)
    }
}

// MARK: - Preview

#Preview("Sign Up") {
    NavigationStack {
        SignUpView(viewModel: AuthViewModel())
    }
}
