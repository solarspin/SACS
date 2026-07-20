//
//  LockedOutView.swift
//  BankSmartAI
//
//  Story 4 — AC-4.2's visible, never-silent locked-out explanation, plus
//  AC-4.3's fresh-login escape hatch (the only way out of lockout).
//

import SwiftUI
import BankAuth

struct LockedOutView: View {
    let message: String?
    @Bindable var signInViewModel: LiveSignInViewModel
    let onSignedIn: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)

            Text(message ?? "Biometric sign-in is disabled. Sign in with your email and password to continue.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()

            SignInView(viewModel: signInViewModel, onSignedIn: onSignedIn)
        }
        .padding()
    }
}
