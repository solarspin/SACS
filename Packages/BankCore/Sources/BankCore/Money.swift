import Foundation

/// An exact amount of money.
///
/// Every balance, transfer amount, and limit in BankSmartAI is a `Money`.
/// The decision was made once, before any AI agent booted, and every AI
/// agent inherits it: there is deliberately no way to construct `Money`
/// from a `Double`, so a floating-point value cannot enter a financial
/// path without an explicit, reviewable conversion — which SecOps flags
/// on sight.
public struct Money: Equatable, Hashable, Codable, Sendable {
    /// Exact decimal amount. Never a `Double`.
    public let amount: Decimal
    /// ISO-4217 currency code. The demo gateway is USD-only.
    public let currency: String

    public init(amount: Decimal, currency: String = "USD") {
        self.amount = amount
        self.currency = currency
    }

    /// Parses the gateway's exact decimal strings (e.g. `"8600000.00"`).
    /// Returns `nil` rather than guessing on malformed input — a missing
    /// or mangled amount is a decode failure, not a zero.
    public init?(string: String, currency: String = "USD") {
        guard let value = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")),
              value.isNaN == false
        else { return nil }
        self.init(amount: value, currency: currency)
    }
}

extension Money: Comparable {
    /// Comparing money in different currencies is a programmer error the
    /// type cannot express; the demo app is single-currency by design.
    public static func < (lhs: Money, rhs: Money) -> Bool {
        precondition(lhs.currency == rhs.currency, "currency mismatch")
        return lhs.amount < rhs.amount
    }
}

extension Money: CustomStringConvertible {
    public var description: String { "\(amount) \(currency)" }
}
