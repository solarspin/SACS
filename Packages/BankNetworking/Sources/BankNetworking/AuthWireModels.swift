import Foundation

/// The exact `POST /auth/login` / `POST /auth/refresh` success body
/// (see `Gateway/README.md`). Field names match the wire precisely.
struct AuthSuccessResponse: Decodable {
    let token: String
    let role: String
    let expiresInSeconds: Int
    let refreshToken: String
    let refreshExpiresInSeconds: Int
}

/// The gateway's uniform error body: `{ "error": "..." }`.
struct AuthErrorResponse: Decodable {
    let error: String
}
