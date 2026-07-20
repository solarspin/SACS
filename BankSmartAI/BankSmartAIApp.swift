//
//  BankSmartAIApp.swift
//  BankSmartAI
//
//  Created by RogTwo on 7/14/26.
//

import SwiftUI
import BankAuth
import BankNetworking

@main
struct BankSmartAIApp: App {
    // The composition root (architecture/PLAN.md: "App -> all packages,
    // composition root only"). AuthSessionRepository and
    // ReentryGateRepository MUST share one LockoutPolicy and one
    // AuthGatewayClient instance — see both protocols' own doc comments;
    // Story 4's 6-failure window is one combined count, not one per
    // repository.
    private let sessionRepository: AuthSessionRepository
    private let reentryRepository: ReentryGateRepository

    init() {
        let gatewayClient = LiveAuthGatewayClient()
        let lockoutPolicy = LiveLockoutPolicy()
        sessionRepository = LiveAuthSessionRepository(
            gatewayClient: gatewayClient,
            lockoutPolicy: lockoutPolicy
        )
        reentryRepository = LiveReentryGateRepository.live(
            gatewayClient: gatewayClient,
            idleTimeoutPolicy: LiveIdleTimeoutPolicy(),
            lockoutPolicy: lockoutPolicy,
            enrollmentPreference: LiveBiometricEnrollmentPreferenceStoring()
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(sessionRepository: sessionRepository, reentryRepository: reentryRepository)
        }
    }
}
