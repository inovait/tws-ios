//
//  ExtractResources.swift
//  TWSSnippets
//
//  Created by Miha Hozjan on 30. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
@_spi(Internals) import TWSModels

class ExtractResources {

    class func from(bundle: TWSSharedSnippetBundle) -> [TWSSnippet.Attachment: String] {
        bundle.resources
    }
}
