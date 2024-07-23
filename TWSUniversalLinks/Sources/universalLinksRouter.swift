//
//  universalLinksRouter.swift
//  TWSUniversalLinks
//
//  Created by Miha Hozjan on 28. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import URLRouting

let universalLinksRouter = OneOf {

    Route(.case(UniversalLinkRoute.snippet(id:))) {
        Path { "shared" }
        Path { Parse(.string) }
        End().pullback(\.path)
    }
}
