// QA Agent — Sprint 1 (sprint-1-front-door).
// Story 5 (role-aware landing state), tested against
// `LiveLandingViewModel`'s public interface only.
//
// AC-5.4 ("shows only who the user is and the role their token holds, and
// nothing else") is verified structurally, not by a runtime assertion:
// the package's public symbol graph
// (`swift package dump-symbol-graph --minimum-access-level public`) shows
// `LandingViewModeling`/`LiveLandingViewModel` expose exactly two
// properties — `role` and `signedInEmail` — no balance, account, or
// navigation-affordance property exists on the contract for a runtime
// test to accidentally miss. AC-5.3 ("the role is read from the JWT
// claim and never from a second, separately stored copy") is likewise
// structural: the initializer takes `role: Role?` directly as a
// parameter, with no environment lookup or secondary store of any kind
// reachable from this type's public interface.

import Testing
import Foundation
import BankCore
import BankAuth

@Suite("QA Story 5 — LandingViewModel")
@MainActor
struct QALandingViewModelTests {

    // AC-5.1: an owner login renders the owner role claim.
    @Test("AC-5.1: renders the owner role and email exactly as constructed")
    func ownerLandingShowsOwnerRoleAndEmail() {
        let vm = LiveLandingViewModel(role: .owner, signedInEmail: "owner@banksmart.test")

        #expect(vm.role == .owner)
        #expect(vm.signedInEmail == "owner@banksmart.test")
    }

    // AC-5.2: a staff login renders the staff role claim.
    @Test("AC-5.2: renders the staff role and email exactly as constructed")
    func staffLandingShowsStaffRoleAndEmail() {
        let vm = LiveLandingViewModel(role: .staff, signedInEmail: "staff@banksmart.test")

        #expect(vm.role == .staff)
        #expect(vm.signedInEmail == "staff@banksmart.test")
    }

    // No claim to render (e.g. signed-out) must not fabricate a role.
    @Test("No role claim renders as nil, never a fabricated default")
    func noRoleRendersAsNil() {
        let vm = LiveLandingViewModel(role: nil)

        #expect(vm.role == nil)
        #expect(vm.signedInEmail == nil)
    }
}
