//
//  StorageCodable.swift
//  Playground
//
//  Created by Miha Hozjan on 14. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

protocol StorageCodable: Codable, RawRepresentable { }

extension Source: StorageCodable {

    init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let type = try? JSONDecoder().decode(SourceType.self, from: data)
        else { return nil }
        self = .init(type: type)
    }

    var rawValue: String {
        guard
            let data = try? JSONEncoder().encode(type),
            let result = String(data: data, encoding: .utf8)
        else { return "" }
        return result
    }
}
