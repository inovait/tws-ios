//
//  SocketMessage.swift
//  TWSCommon
//
//  Created by Miha Hozjan on 19. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels

public struct SocketMessage: CustomDebugStringConvertible {

    public let id: UUID
    public let type: MessageType
    public let snippet: TWSSnippet?

    init?(json: [AnyHashable: Any]) {
        guard
            let typeStr = json["type"] as? String,
            let dataJson = json["data"] as? [AnyHashable: Any],
            let idStr = dataJson["id"] as? String,
            let id = UUID(uuidString: idStr),
            let type = MessageType(
                rawValue: typeStr
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
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
    init(id: UUID, type: MessageType, snippet: TWSSnippet? = nil) {
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
            let snippet = try JSONDecoder().decode(TWSSnippet.self, from: jsonData)
            return snippet
        } catch {
            logger.err("Failed to parse snippet from socket: \(error.localizedDescription)")
            return nil
        }
    }
}

public extension SocketMessage {

    enum MessageType: String {

        case created = "SNIPPET_CREATED"
        case updated = "SNIPPET_UPDATED"
        case deleted = "SNIPPET_DELETED"
    }
}

public enum SocketMessageReadError: Error {

    case failedToParse(String)
}
