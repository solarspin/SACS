//
//  BiometricGateProgressView.swift
//  BankSmartAI
//
//  Stories 2/3 — shown while presentGateIfNeeded() is running the OS
//  biometric/passcode prompt, and as a retry affordance if the prompt
//  just failed or was canceled (the gate never falls through to signed-in
//  content on its own — AC-2.1).
//

import SwiftUI

struct BiometricGateProgressView: View {
    let isRunning: Bool
    let onRetry: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            if isRunning {
                ProgressView()
                Text("Verifying…")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "faceid")
                    .font(.largeTitle)
                Text("Biometric sign-in didn't complete.")
                Button("Try Again") {
                    Task { await onRetry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
