//
//  SharedSnippets.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 28. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSSnippet
import TWSModels
import ComposableArchitecture

private extension URL {
    static func snippets(for config: TWSConfiguration) -> URL {
        .documentsDirectory
        .appending(component: "\(config.organizationID)_\(config.projectID)_snippets.json")
    }
}

extension PersistenceReaderKey where Self == FileStorageKey<IdentifiedArrayOf<TWSSnippetFeature.State>> {
    static func snippets(for config: TWSConfiguration) -> Self {
        .fileStorage(.snippets(for: config))
    }
}
