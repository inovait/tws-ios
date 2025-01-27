import Foundation
import TWSModels
import TWSFormatters

public struct TWSAPI {

    public let getProject: @Sendable (
        _ projectId: TWSBasicConfiguration
    ) async throws(APIError) -> (TWSProject, Date?)

    public var getSharedToken: @Sendable (
        _ sharedId: TWSSharedConfiguration
    ) async throws(APIError) -> String

    public var getSnippetByShareToken: @Sendable (
        _ token: String
    ) async throws(APIError) -> (TWSProject, Date?)

    public let getResource: @Sendable (
        TWSSnippet.Attachment, [String: String]
    ) async throws(APIError) -> String

    static func live(
        host: String
    ) -> Self {
        .init(
            getProject: { project throws(APIError) in
                let result = try await Router.make(request: .init(
                        method: .get,
                        path: "/projects/\(project.id)/snippets",
                        host: host,
                        queryItems: [],
                        headers: [:],
                        auth: true
                    ))

                do {
                    let decoder = JSONDecoder()

                    decoder.dateDecodingStrategy = isoDateDecoder

                    return (try decoder.decode(TWSProject.self, from: result.data), result.dateOfResponse)
                } catch {
                    throw APIError.decode(error)
                }
            },
            getSharedToken: { shared throws(APIError) in
                let result = try await Router.make(request: .init(
                    method: .get,
                    path: "/shared/\(shared.id)",
                    host: host,
                    queryItems: [],
                    headers: [
                        "Accept": "application/json"
                    ],
                    auth: true
                ))

                do {
                    let sharedTokenResponse = try JSONDecoder().decode(TWSSharedToken.self, from: result.data)
                    return sharedTokenResponse.shareToken
                } catch {
                    throw APIError.decode(error)
                }
            },
            getSnippetByShareToken: { token throws(APIError) in
                let result = try await Router.make(request: .init(
                    method: .get,
                    path: "/snippets/shared",
                    host: host,
                    queryItems: [
                        URLQueryItem(name: "shareToken", value: token)
                    ],
                    headers: [
                        "Accept": "application/json"
                    ],
                    auth: true
                ))

                do {
                    return (try JSONDecoder().decode(TWSProject.self, from: result.data), result.dateOfResponse)
                } catch {
                    throw APIError.decode(error)
                }
            },
            getResource: { attachment, headers throws(APIError) in
                let result = try await Router.make(request: .init(
                    method: .get,
                    path: attachment.url.path(),
                    host: attachment.url.host() ?? "",
                    queryItems: [],
                    headers: headers,
                    auth: false
                ))

                if let payload = String(data: result.data, encoding: .utf8) {
                    return payload
                }

                throw .decode(NSError(domain: "invalid-string", code: -1))
            }
        )
    }
}
