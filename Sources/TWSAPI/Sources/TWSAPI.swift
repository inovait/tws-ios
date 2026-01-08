import Foundation
@_spi(Internals) import TWSModels
import TWSFormatters

public struct TWSAPI {

    public let getProject: @Sendable (
        _ projectId: TWSBasicConfiguration
    ) async throws(APIError) -> (TWSProject, Date?)

    public let getResource: @Sendable (
        TWSSnippet.Attachment, [String: String]
    ) async throws(APIError) -> ResourceResponse
    
    public let getCampaign: @Sendable (
        TWSBasicConfiguration, String
    ) async throws(APIError) -> TWSCampaign
    
    public let registerForRemoteNotifications: @Sendable (
        _ projectId: TWSBasicConfiguration,
        _ deviceToken: String
    ) async throws(APIError) -> Void

    static func live(
        baseUrl: TWSBaseUrl
    ) -> Self {
        .init(
            getProject: { project throws(APIError) in
                let result = try await Router.make(request: .init(
                        method: .get,
                        scheme: baseUrl.scheme,
                        path: "/projects/\(project.id)/snippets/v1",
                        host: baseUrl.host,
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
            getResource: { attachment, headers throws(APIError) in
                let result = try await Router.make(request: .init(
                    method: .get,
                    url: attachment.url,
                    headers: headers,
                    auth: false)
                )
                
                if let payload = String(data: result.data, encoding: .utf8) {
                    return ResourceResponse(responseUrl: result.responseUrl, data: payload)
                }

                throw .decode(NSError(domain: "invalid-string", code: -1))
            },
            getCampaign: { project, campaignTrigger throws(APIError) in

                let result = try await Router.make(request: .init(
                    method: .post,
                    scheme: baseUrl.scheme,
                    path: "/projects/\(project.id)/events",
                    host: baseUrl.host,
                    queryItems: [],
                    headers: ["content-type":"application/json-patch+json"],
                    auth: true,
                    body: ["event": campaignTrigger]
                ))
                
                do {
                    let decoder = JSONDecoder()

                    decoder.dateDecodingStrategy = isoDateDecoder
                    
                    return try decoder.decode(TWSCampaign.self, from: result.data)
                } catch {
                    throw APIError.decode(error)
                }
            },
            registerForRemoteNotifications: { project, deviceToken throws(APIError) in
                let tokenParameter = URLQueryItem(name: "token", value: deviceToken)
                
                let request: Request = .init(
                    method: .post,
                    scheme: baseUrl.scheme,
                    path: "/projects/\(project.id)/devicetoken",
                    host: baseUrl.host,
                    queryItems: [tokenParameter],
                    headers: [:],
                    auth: true
                )
                
                let apiResult = try await Router.make(request: request)
            }
        )
    }
}
