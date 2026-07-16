import BankCore

/// Consistent, role-based labeling for the two Sprint 1 roles (Story 5),
/// kept in BankDesign rather than BankAuth so a feature package never
/// owns a raw display string or color choice — that's a design-system
/// concern, and BankAuth's landing view model only asks "what role is
/// this" and hands the answer to a view that renders it.
///
/// Sprint 1 keeps this deliberately thin: a label and a semantic tint
/// token name (resolved to an actual color asset by the implementation)
/// — nothing here computes or contains a UI layout, so it remains a
/// contract, not a view.
///
/// Owned by: BankDesign. May be depended on by: BankAuth (the only
/// feature package in Sprint 1 scope).
public protocol RoleBadgeStyling: Sendable {
    /// Human-readable label for the role (AC-5.1, AC-5.2).
    func label(for role: Role) -> String

    /// Semantic tint token name distinguishing owner from staff.
    func tintToken(for role: Role) -> String
}
