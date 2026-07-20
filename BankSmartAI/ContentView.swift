//
//  ContentView.swift
//  Bank
//  Created by RogTwo on 7/14/26.
//
//  The Sprint 1 root coordinator. Owns the shared repositories' derived
//  view models and switches screens based only on what BankAuth's public
//  contracts report — no new business logic, no new view models.
//
//  Two distinct routing signals, matched to two distinct contracts:
//  - `gateViewModel.phase` (BiometricGateViewModeling) drives everything
//    on cold launch and on return-from-background (Stories 2/3/4),
//    exactly per its own doc comment.
//  - `localRoute` is a small piece of app-target-only navigation state
//    for the one-shot path SignInViewModeling's doc comment assigns to
//    "the caller": after an interactive sign-in, go straight to Story
//    8's enrollment offer or straight to the Story 5 landing state,
//    never back through the gate (see this assignment's SELF-REPORT for
//    why re-running presentGateIfNeeded() here would be wrong).
//

import SwiftUI
import BankAuth
import BankCore

struct ContentView: View {
    let sessionRepository: AuthSessionRepository
    let reentryRepository: ReentryGateRepository

    @State private var gateViewModel: LiveBiometricGateViewModel
    @State private var signInViewModel: LiveSignInViewModel
    @State private var localRoute: LocalRoute?
    @State private var isGateRunning = false
    @Environment(\.scenePhase) private var scenePhase

    private enum LocalRoute: Equatable {
        case enrollmentOffer
        case landed(role: Role)
    }

    init(sessionRepository: AuthSessionRepository, reentryRepository: ReentryGateRepository) {
        self.sessionRepository = sessionRepository
        self.reentryRepository = reentryRepository
        _gateViewModel = State(initialValue: LiveBiometricGateViewModel(
            sessionRepository: sessionRepository,
            reentryRepository: reentryRepository
        ))
        _signInViewModel = State(initialValue: LiveSignInViewModel(
            sessionRepository: sessionRepository,
            reentryRepository: reentryRepository
        ))
    }

    var body: some View {
        content
            .task {
                await runGate()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                localRoute = nil
                Task { await runGate() }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch localRoute {
        case .enrollmentOffer:
            BiometricEnrollmentPromptView(
                viewModel: LiveBiometricEnrollmentPromptViewModel(reentryRepository: reentryRepository),
                onFinished: { await finishEnrollmentOffer() }
            )
        case .landed(let role):
            landingView(for: role)
        case nil:
            switch gateViewModel.phase {
            case .lockedOut:
                LockedOutView(
                    message: gateViewModel.lockedOutMessage,
                    signInViewModel: signInViewModel,
                    onSignedIn: { await handleSignInOutcome() }
                )
            case .signedOut:
                SignInView(viewModel: signInViewModel, onSignedIn: { await handleSignInOutcome() })
            case .awaitingBiometricGate:
                BiometricGateProgressView(isRunning: isGateRunning, onRetry: { await runGate() })
            case .signedIn(let role):
                landingView(for: role)
            }
        }
    }

    private func landingView(for role: Role) -> LandingView {
        LandingView(
            viewModel: LiveLandingViewModel(
                role: role,
                signedInEmail: signInViewModel.email.isEmpty ? nil : signInViewModel.email
            ),
            onSignOut: { await handleSignOut() }
        )
    }

    private func handleSignOut() async {
        await sessionRepository.signOut()
        localRoute = nil
        await runGate()
    }

    private func runGate() async {
        isGateRunning = true
        await gateViewModel.presentGateIfNeeded()
        isGateRunning = false
    }

    private func handleSignInOutcome() async {
        switch signInViewModel.outcome {
        case .offerBiometricEnrollment:
            localRoute = .enrollmentOffer
        case .signedIn(let role):
            localRoute = .landed(role: role)
        case .none:
            break
        }
    }

    private func finishEnrollmentOffer() async {
        if let role = await sessionRepository.currentRole {
            localRoute = .landed(role: role)
        } else {
            localRoute = nil
            await runGate()
        }
    }
}
