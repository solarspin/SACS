import Foundation
import Security

/// The raw wire tokens plus their expiries, exactly as persisted in the
/// Keychain. Never `public` — this is the one place in the app the raw
/// `token`/`refreshToken` strings exist as values, matching
/// `AuthSession`'s own doc comment: no other type, and no other
/// package, ever sees them.
struct StoredSession: Codable, Equatable {
    let token: String
    let expiresAt: Date
    /// `nil` after `discardRefreshToken()` (DECISION Q11) — the session
    /// token stays usable for the rest of its own lifetime, but nothing
    /// can silently refresh past it anymore.
    let refreshToken: String?
    let refreshExpiresAt: Date?
}

/// Keychain-backed storage for exactly one `StoredSession` at a time —
/// Sprint 1 has one signed-in identity per device. `kSecAttrAccessible`
/// is fixed to `kSecAttrAccessibleAfterFirstUnlock` (S3) on every write;
/// never `...Always`.
struct KeychainSessionStore {
    let service: String

    init(service: String = "com.banksmartai.auth.session") {
        self.service = service
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
    }

    func save(_ session: StoredSession) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(session)

        let update: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw AuthError.transport(.unknown("Keychain update failed (status \(updateStatus))"))
        }

        var add = baseQuery
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw AuthError.transport(.unknown("Keychain write failed (status \(addStatus))"))
        }
    }

    func load() -> StoredSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        // A corrupted or unreadable stored session is treated the same
        // as no stored session (AC-4.4: no cached token grants entry) —
        // this isn't discarding a signal anything downstream could act
        // on differently; both outcomes mean "no valid session."
        do {
            return try decoder.decode(StoredSession.self, from: data)
        } catch {
            return nil
        }
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
