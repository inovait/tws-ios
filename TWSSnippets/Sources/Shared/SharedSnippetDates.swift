//
//  SharedSnippetDates.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 15. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
import ComposableArchitecture

private extension URL {
    static func snippetDates(for config: TWSConfiguration) -> URL {
        .documentsDirectory
        .appending(component: "\(config.organizationID)_\(config.projectID)_snippets_dates.json")
    }
}

extension PersistenceReaderKey where Self == FileStorageKey<[UUID: SnippetDateInfo]> {
    static func snippetDates(for config: TWSConfiguration) -> Self {
        .fileStorage(.snippetDates(for: config))
    }
}
