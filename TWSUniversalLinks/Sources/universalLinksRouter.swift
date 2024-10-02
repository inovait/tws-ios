//
//  universalLinksRouter.swift
//  TWSUniversalLinks
//
//  Created by Miha Hozjan on 28. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import URLRouting

private let universalLinksRouter = OneOf {
    Route(.case(UniversalLinkRoute.snippet(id:))) {
        OneOf {
            Host("thewebsnippet.dev")
        }
        Path { "shared" }
        Path { Parse(.string) }
        End().pullback(\.path)
    }
}

public class TWSUniversalLinkRouter {

    public class func route(for url: URL) throws -> UniversalLinkRoute {
        try universalLinksRouter.match(url: url)
    }
}
