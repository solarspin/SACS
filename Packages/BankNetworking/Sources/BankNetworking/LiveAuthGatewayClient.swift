import Foundation
import BankCore

/// The `AuthGatewayClient` conformance backing every real signIn/refresh
/// call against `POST /auth/login` and `POST /auth/refresh`. An `actor`
/// so concurrent calls (e.g. a foreground refresh racing a background
/// sign-out) serialize instead of racing on the same Keychain entry.
public actor LiveAuthGatewayClient: AuthGatewayClient {
    private let baseURL: URL
    private let urlSession: URLSession
    private let jwtDecoder: JWTRoleClaimDecoding
    private let keychain: KeychainSessionStore

    public init(
        baseURL: URL? = nil,
        urlSession: URLSession = .shared,
        jwtDecoder: JWTRoleClaimDecoding = DefaultJWTRoleClaimDecoder(),
        keychainService: String = "com.banksmartai.auth.session"
    ) {
        self.baseURL = baseURL ?? GatewayConfiguration.baseURL
        self.urlSession = urlSession
        self.jwtDecoder = jwtDecoder
        self.keychain = KeychainSessionStore(service: keychainService)
    }

    public func signIn(email: String, password: Credential) async throws -> AuthSession {
        let (data, http) = try await post(
            path: "/auth/login",
            body: ["email": email, "password": password.value]
        )
        switch http.statusCode {
        case 200:
            return try decodeAndStore(data)
        case 401:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.transport(mapFailureStatus(http.statusCode, data))
        }
    }

    public func refreshSession() async throws -> AuthSession {
        // No stored refresh token to send is the same outcome, to every
        // caller, as the gateway rejecting one (DECISION Q9/AC-6.4,
        // AC-6.5): fall back to a fresh `signIn`.
        guard let refreshToken = keychain.load()?.refreshToken else {
            throw AuthError.refreshFailed
        }

        let (data, http) = try await post(
            path: "/auth/refresh",
            body: ["refreshToken": refreshToken]
        )
        switch http.statusCode {
        case 200:
            return try decodeAndStore(data)
        case 401:
            // AC-6.4: the app discards the stored refreshToken and never
            // retries it. Nothing else cached remains usable either —
            // AC-6.2's precondition for even calling this is that the
            // session token is already expired or idle-timed-out — so
            // clearing the whole entry, not just the refresh half, is
            // what "requires a fresh POST /auth/login" already implies.
            keychain.clear()
            throw AuthError.refreshFailed
        default:
            throw AuthError.transport(mapFailureStatus(http.statusCode, data))
        }
    }

    public func discardRefreshToken() async {
        guard let stored = keychain.load(), stored.refreshToken != nil else { return }
        let cleared = StoredSession(
            token: stored.token,
            expiresAt: stored.expiresAt,
            refreshToken: nil,
            refreshExpiresAt: nil
        )
        do {
            try keychain.save(cleared)
        } catch {
            // `discardRefreshToken()` is a non-throwing requirement on
            // `AuthGatewayClient` — there is no channel to surface a
            // Keychain write failure to the caller. This is not a `try?`
            // silently swallowing it: it's surfaced loudly in debug
            // builds and flagged in this assignment's SELF-REPORT as a
            // contract gap worth Seam 3's attention. No sensitive value
            // is in `error` — only an OSStatus-derived message (S9).
            assertionFailure("discardRefreshToken: Keychain write failed — \(error)")
        }
    }

    public func clearSession() async {
        keychain.clear()
    }

    public var currentSession: AuthSession? {
        get async {
            guard let stored = keychain.load() else { return nil }
            do {
                let role = try jwtDecoder.role(fromJWT: stored.token)
                return AuthSession(
                    role: role,
                    expiresAt: stored.expiresAt,
                    refreshExpiresAt: stored.refreshExpiresAt ?? .distantPast
                )
            } catch {
                // An unreadable stored token is, to every caller, no
                // different from no stored token (AC-4.4) — same
                // reasoning as `KeychainSessionStore.load()`.
                return nil
            }
        }
    }

    // MARK: - Wire plumbing

    private func post(path: String, body: [String: String]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw AuthError.transport(.unknown("failed to encode request body"))
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let urlError as URLError {
            throw AuthError.transport(mapURLError(urlError))
        } catch {
            throw AuthError.transport(.unknown("\(error)"))
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.transport(.unknown("non-HTTP response from gateway"))
        }
        return (data, http)
    }

    private func decodeAndStore(_ data: Data) throws -> AuthSession {
        let decoded: AuthSuccessResponse
        do {
            decoded = try JSONDecoder().decode(AuthSuccessResponse.self, from: data)
        } catch {
            throw AuthError.transport(.decoding("malformed /auth/login or /auth/refresh response"))
        }

        // AC-1.5: the role claim is read from the JWT itself, never the
        // response's separate top-level `role` field, even though the
        // gateway always sets them identically.
        let role = try jwtDecoder.role(fromJWT: decoded.token)

        let now = Date()
        let expiresAt = now.addingTimeInterval(TimeInterval(decoded.expiresInSeconds))
        let refreshExpiresAt = now.addingTimeInterval(TimeInterval(decoded.refreshExpiresInSeconds))
        let stored = StoredSession(
            token: decoded.token,
            expiresAt: expiresAt,
            refreshToken: decoded.refreshToken,
            refreshExpiresAt: refreshExpiresAt
        )
        try keychain.save(stored)

        return AuthSession(role: role, expiresAt: expiresAt, refreshExpiresAt: refreshExpiresAt)
    }

    private func mapFailureStatus(_ status: Int, _ data: Data) -> AppError {
        let message = (try? JSONDecoder().decode(AuthErrorResponse.self, from: data))?.error
            ?? "unexpected gateway response (status \(status))"
        return status >= 500 ? .serverError(message) : .unknown(message)
    }

    private func mapURLError(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .offline
        case .timedOut:
            return .timeout
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .serverUnreachable
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
