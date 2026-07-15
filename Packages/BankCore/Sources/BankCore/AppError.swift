import Foundation

/// Typed errors the app can respond to meaningfully.
/// A 401 is a control signal (session over — reauthenticate), never a
/// message to display. A 403 is an authorization boundary holding, which
/// the UI must present truthfully — not as a malfunction.
public enum AppError: Error, Equatable, Sendable {
    case offline
    case timeout
    case serverUnreachable
    case unauthorized            // 401 — control signal: end session
    case forbidden(String)       // 403 — role lacks the authority
    case serverError(String)
    case decoding(String)
    case unknown(String)
}

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .offline:            return "No network connection."
        case .timeout:            return "The server took too long to respond. Try again."
        case .serverUnreachable:  return "Cannot reach the banking gateway."
        case .unauthorized:       return "Your session has expired. Please sign in again."
        case .forbidden(let m):   return "Not permitted for your role: \(m)"
        case .serverError(let m): return "Server error: \(m)"
        case .decoding(let m):    return "Unexpected response from the gateway: \(m)"
        case .unknown(let m):     return m
        }
    }
}
