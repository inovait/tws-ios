//
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

class Router {

    private static let authManager = AuthManager()

    private static let dateFormatter = {
        let newDateFormatter = DateFormatter()
        newDateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ssZ"
        newDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        newDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return newDateFormatter
    }()

    class func make(request: Request, retryEnabled: Bool = true) async throws(APIError) -> APIResult {
        var components = URLComponents()
        components.scheme = "https"
        components.host = request.host
        components.path = request.path

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            fatalError("Failed to create an URL")
        }

        var urlRequest = URLRequest(url: url, timeoutInterval: 60)
        urlRequest.httpMethod = request.method.rawValue.uppercased()
        for header in request.headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        logger.info(urlRequest.debugDescription)

        do {
            if request.auth {
                let token = try await authManager.getAccessToken(false)
                urlRequest.setValue(
                    "Bearer \(token)",
                    forHTTPHeaderField: "Authorization"
                )
            }
            let result = try await URLSession.shared.data(for: urlRequest)
            guard
                let httpResult = result.1 as? HTTPURLResponse
            else {
                fatalError("Received a response without being an HTTPURLResponse?")
            }

            if 200..<300 ~= httpResult.statusCode {
                var serverDate: Date?
                if let responseHeaders = httpResult.allHeaderFields as? [String: String],
                   let serverDateHeader = responseHeaders["Date"] {
                    serverDate = dateFormatter.date(from: serverDateHeader)
                }
                return .init(
                    data: result.0,
                    dateOfResponse: serverDate
                )
            } else if httpResult.statusCode == 401 {
                if retryEnabled {
                    try await authManager.forceRefreshTokens()
                    return try await make(request: request, retryEnabled: false)
                } else {
                    throw APIError.server(httpResult.statusCode, result.0)
                }
            } else {
                logger.err(String(data: result.0, encoding: .utf8) ?? "null")
                throw APIError.server(httpResult.statusCode, result.0)
            }
        } catch {
            throw APIError.local(error)
        }
    }
}

struct APIResult {

    let data: Data
    let dateOfResponse: Date?
}

public enum APIError: Error {

    case local(Error)
    case server(Int, Data)
    case decode(Error)
    case auth(String)
}
