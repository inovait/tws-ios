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
import TWSModels
import TWSFormatters

public struct SocketMessage: CustomDebugStringConvertible, Sendable {

    public let id: TWSSnippet.ID
    public let type: MessageType
    public let snippet: TWSSnippet?

    init?(json: [AnyHashable: Any]) {
        guard
            let typeStr = json["type"] as? String,
            let dataJson = json["data"] as? [AnyHashable: Any],
            let id = dataJson["id"] as? TWSSnippet.ID,
            let type = MessageType(
                rawValue: typeStr
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
        else {
            return nil
        }

        self.id = id
        self.type = type
        self.snippet = Self._parseSnippet(dataJson)
    }

    #if DEBUG
    // periphery:ignore - Used in unit tests
    init(id: TWSSnippet.ID, type: MessageType, snippet: TWSSnippet? = nil) {
        self.id = id
        self.type = type
        self.snippet = snippet
    }
    #endif

    public var debugDescription: String {
        """
        \(type) snippet: \(id)
        """
    }

    private static func _parseSnippet(_ json: [AnyHashable: Any]) -> TWSSnippet? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = isoDateDecoder

            return try decoder.decode(TWSSnippet.self, from: jsonData)
        } catch {
            logger.warn("Failed to parse snippet from socket: \(error.localizedDescription)")
            return nil
        }
    }
}

public extension SocketMessage {

    enum MessageType: String, Sendable {

        case created = "snippetCreated"
        case updated = "snippetUpdated"
        case deleted = "snippetDeleted"
    }
}

public enum SocketMessageReadError: Error {

    case failedToParse(String)
}
