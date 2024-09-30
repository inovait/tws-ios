//
//  SharedResources.swift
//  TWSSnippets
//
//  Created by Miha Hozjan on 30. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
import ComposableArchitecture

private extension URL {

    static func resources(for config: TWSConfiguration) -> URL {
        .documentsDirectory
        .appending(component: "\(config.organizationID)_\(config.projectID)_resources.json")
    }
}

extension PersistenceReaderKey where Self == FileStorageKey<[TWSSnippet.Attachment: String]> {

    static func resources(for config: TWSConfiguration) -> Self {
        .fileStorage(.resources(for: config))
    }
}
