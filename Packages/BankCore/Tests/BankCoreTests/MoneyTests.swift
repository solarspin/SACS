import Testing
import Foundation
@testable import BankCore

@Test func parsesGatewayDecimalStrings() {
    let m = Money(string: "8600000.00")
    #expect(m == Money(amount: Decimal(string: "8600000.00")!))
}

@Test func rejectsMalformedAmounts() {
    #expect(Money(string: "not-money") == nil)
    #expect(Money(string: "") == nil)
}

@Test func exactArithmeticSurvivesTheClassicFloatTrap() {
    // 0.1 + 0.2 == 0.3 exactly — the assertion Double famously fails.
    let a = Money(string: "0.10")!, b = Money(string: "0.20")!
    #expect(a.amount + b.amount == Decimal(string: "0.30")!)
}

@Test func comparesWithinCurrency() {
    #expect(Money(string: "99.00")! < Money(string: "100.00")!)
}
