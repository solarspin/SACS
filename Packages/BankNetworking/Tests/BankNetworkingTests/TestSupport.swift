import Foundation
@testable import BankNetworking

/// Builds a JWT-shaped (but unsigned-for-real) token matching
/// `Gateway/server.js`'s `sign()` shape closely enough for
/// `DefaultJWTRoleClaimDecoder` to exercise: three dot-separated
/// base64url segments, payload containing a `role` claim. The decoder
/// under test never verifies the signature, so segment 3 is a fixed
/// placeholder.
func makeTestJWT(role: String) -> String {
    func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    let header = base64URL(Data(#"{"alg":"HS256","typ":"JWT"}"#.utf8))
    let payload = base64URL(Data(#"{"role":"\#(role)"}"#.utf8))
    return "\(header).\(payload).test-signature"
}

/// Intercepts every request made through a `URLSession` configured with
/// it, returning canned JSON responses so `LiveAuthGatewayClient` can be
/// tested with no real network or running gateway process. Tests using
/// this must run serialized (`@Suite(.serialized)`) since the stub
/// queues are keyed by path in shared, unlocked static state.
final class StubURLProtocol: URLProtocol {
    // Safe only because every test using this runs serialized
    // (@Suite(.serialized)) — never accessed from more than one test at
    // a time, despite URLProtocol's loading callback running off the
    // main thread.
    nonisolated(unsafe) private static var queues: [String: [(status: Int, json: [String: Any])]] = [:]

    static func enqueue(path: String, status: Int, json: [String: Any]) {
        queues[path, default: []].append((status, json))
    }

    static func reset() {
        queues = [:]
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard
            let url = request.url,
            var queue = Self.queues[url.path],
            !queue.isEmpty
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let next = queue.removeFirst()
        Self.queues[url.path] = queue

        guard
            let data = try? JSONSerialization.data(withJSONObject: next.json),
            let response = HTTPURLResponse(
                url: url,
                statusCode: next.status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotParseResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

func makeStubbedClient(keychainService: String) -> LiveAuthGatewayClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return LiveAuthGatewayClient(
        baseURL: URL(string: "https://gateway.test"),
        urlSession: URLSession(configuration: configuration),
        keychainService: keychainService
    )
}
