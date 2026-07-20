//
//  SignInView.swift
//  BankSmartAI
//
//  Story 1 — bound to LiveSignInViewModel's public interface only.
//

import SwiftUI
import BankAuth

struct SignInView: View {
    @Bindable var viewModel: LiveSignInViewModel
    let onSignedIn: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign In")
                .font(.title2)
                .bold()

            TextField("Email", text: $viewModel.email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Button {
                Task {
                    await viewModel.signIn()
                    await onSignedIn()
                }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSubmitting || viewModel.email.isEmpty || viewModel.password.isEmpty)
        }
        .padding()
    }
}
