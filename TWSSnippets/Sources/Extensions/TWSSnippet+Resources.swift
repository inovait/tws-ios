//
//  TWSSnippet+Resources.swift
//  Playground
//
//  Created by Miha Hozjan on 19. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSCommon
import ComposableArchitecture
@_spi(Internals) import TWSModels

extension TWSSnippet {

    func hasResources(for configuration: TWSConfiguration) -> Bool {
        assert(Thread.isMainThread)
        var headers = [Attachment: [String: String]]()
        let preloaded = SharedReader(wrappedValue: [:], .resources(for: configuration))
        let attachments = self.allResources(headers: &headers)
        return attachments.allSatisfy { preloaded[$0].wrappedValue != nil }
    }
}
