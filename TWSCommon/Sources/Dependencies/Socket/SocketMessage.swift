//
//  SocketMessage.swift
//  TWSCommon
//
//  Created by Miha Hozjan on 19. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public struct SocketMessage: CustomDebugStringConvertible {

    public let id: UUID
    public let type: MessageType
    public let target: URL?

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
        self.target = Self._parseTarget(dataJson)
    }

    #if DEBUG
    // periphery:ignore - Used in unit tests
    init(id: UUID, type: MessageType, target: URL? = nil) {
        self.id = id
        self.type = type
        self.target = target
    }
    #endif

    public var debugDescription: String {
        """
        \(type) snippet: \(id)
        """
    }

    private static func _parseTarget(_ json: [AnyHashable: Any]) -> URL? {
        guard let urlString = json["target"] as? String
        else { return nil }
        return URL(string: urlString)
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
