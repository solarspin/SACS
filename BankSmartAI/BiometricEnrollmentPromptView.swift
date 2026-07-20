//
//  BiometricEnrollmentPromptView.swift
//  BankSmartAI
//
//  Story 8 — bound to BiometricEnrollmentPromptViewModeling only.
//

import SwiftUI
import BankAuth

struct BiometricEnrollmentPromptView: View {
    let viewModel: BiometricEnrollmentPromptViewModeling
    let onFinished: () async -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "faceid")
                .font(.largeTitle)

            Text("Use Face ID to sign in faster?")
                .font(.title3)
                .multilineTextAlignment(.center)

            Text("You can change this later in Settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Enable Face ID") {
                Task {
                    isProcessing = true
                    await viewModel.accept()
                    isProcessing = false
                    await onFinished()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)

            Button("Not Now") {
                Task {
                    isProcessing = true
                    await viewModel.decline()
                    isProcessing = false
                    await onFinished()
                }
            }
            .disabled(isProcessing)
        }
        .padding()
    }
}
