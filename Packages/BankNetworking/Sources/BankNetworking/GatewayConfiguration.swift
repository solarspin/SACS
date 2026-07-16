import Foundation

/// Reads `GATEWAY_BASE_URL`, wired in from `Secrets.xcconfig` via the
/// app's Info.plist (see `Secrets.example.xcconfig`'s own comment: "The
/// build fails fast and loud if these are missing — see BankNetworking").
/// A missing or malformed value is a deployment misconfiguration, not a
/// recoverable runtime condition, so this fails loudly and immediately
/// rather than falling back to a default gateway URL nobody chose.
enum GatewayConfiguration {
    static var baseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "GATEWAY_BASE_URL") as? String,
            !raw.isEmpty,
            let url = URL(string: raw)
        else {
            preconditionFailure(
                "GATEWAY_BASE_URL is not configured. Copy Secrets.example.xcconfig to " +
                "Secrets.xcconfig, fill in GATEWAY_BASE_URL, and confirm it reaches " +
                "Info.plist via the app target's build settings."
            )
        }
        return url
    }
}
