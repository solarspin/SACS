//
//  LandingView.swift
//  BankSmartAI
//
//  Story 5 — bound to LandingViewModeling only. Shows role and identity
//  and nothing else (AC-5.4) — the contract has no other property to
//  accidentally render.
//

import SwiftUI
import BankAuth
import BankCore

struct LandingView: View {
    let viewModel: LandingViewModeling
    let onSignOut: () async -> Void

    @State private var isSigningOut = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)

            Text(roleLabel)
                .font(.title2)
                .bold()

            if let email = viewModel.signedInEmail {
                Text(email)
                    .foregroundStyle(.secondary)
            }

            Button("Sign Out") {
                Task {
                    isSigningOut = true
                    await onSignOut()
                    isSigningOut = false
                }
            }
            .disabled(isSigningOut)
            .padding(.top, 8)
        }
        .padding()
    }

    private var roleLabel: String {
        switch viewModel.role {
        case .owner:
            return "Signed in as Owner"
        case .staff:
            return "Signed in as Staff"
        case nil:
            return "Signed in"
        }
    }
}
