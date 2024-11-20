//
//  TWSSharedSnippet+Resources.swift
//  Playground
//
//  Created by Miha Hozjan on 20. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

@_spi(Internals)
public extension TWSSharedSnippet {

    func allResources(
        headers: inout [TWSSnippet.Attachment: [String: String]]
    ) -> [TWSSnippet.Attachment] {
        let attachments = snippet.dynamicResources ?? []
        let homepage = TWSSnippet.Attachment.init(
            url: snippet.target,
            contentType: .html
        )

        headers = [homepage: snippet.headers ?? [:]]

        return [homepage] + attachments
    }
}
