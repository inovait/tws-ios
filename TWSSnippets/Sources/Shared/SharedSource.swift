//
//  SharedSource.swift
//  TWS
//
//  Created by Miha Hozjan on 6. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
import ComposableArchitecture

private extension URL {
    static func source(for config: TWSConfiguration) -> URL {
        .documentsDirectory
        .appendingPathComponent(cacheFolder)
        .appending(component: "\(config.organizationID)_\(config.projectID)_snippets_source.json")
    }
}

extension PersistenceReaderKey where Self == FileStorageKey<TWSSource> {
    static func source(for config: TWSConfiguration) -> Self {
        .fileStorage(.source(for: config))
    }
}
