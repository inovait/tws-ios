//
//  TWSSnippet+Resources.swift
//  Playground
//
//  Created by Miha Hozjan on 20. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

@_spi(Internals)
public extension TWSSnippet {

    func allResources(
        headers: inout [TWSSnippet.Attachment: [String: String]]
    ) -> [TWSSnippet.Attachment] {
        let attachments = dynamicResources ?? []
        let homepage = TWSSnippet.Attachment.init(
            url: target,
            contentType: .html
        )

        headers = [homepage: self.headers ?? [:]]

        return [homepage] + attachments
    }
}
