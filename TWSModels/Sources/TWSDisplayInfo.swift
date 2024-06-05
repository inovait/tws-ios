//
//  TWSDisplayInfo.swift
//  TWSSnippets
//
//  Created by Miha Hozjan on 3. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

public struct TWSDisplayInfo: Codable, Equatable {

    public var displays: [String: Info]

    public init(displays: [String: Info] = [:]) {
        self.displays = displays
    }
}

extension TWSDisplayInfo {

    public struct Info: Codable, Equatable {

        public let id: String
        public let height: CGFloat

        public init(
            id: String,
            height: CGFloat
        ) {
            self.id = id
            self.height = height
        }

        public func height(_ height: CGFloat) -> Self {
            .init(
                id: id,
                height: height
            )
        }
    }
}
