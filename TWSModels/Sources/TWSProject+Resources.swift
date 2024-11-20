//
//  TWSProject+Resources.swift
//  Playground
//
//  Created by Miha Hozjan on 20. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

@_spi(Internals)
public extension TWSProject {

    func allResources(
        headers: inout [TWSSnippet.Attachment: [String: String]]
    ) -> [TWSSnippet.Attachment] {
        let attachments = snippets
            .compactMap(\.dynamicResources)
            .flatMap { $0 }

        var homepages = [TWSSnippet.Attachment]()
        snippets.forEach { snippet in
            let homepage = TWSSnippet.Attachment(
                url: snippet.target,
                contentType: .html
            )

            homepages.append(homepage)
            headers[homepage] = snippet.headers
        }

        return homepages + attachments
    }
}
