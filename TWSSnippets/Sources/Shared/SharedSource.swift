//
//  SharedSource.swift
//  TWSKit
//
//  Created by Miha Hozjan on 6. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
import ComposableArchitecture

extension URL {
    static let source = URL.documentsDirectory.appending(component: "snippets_source.json")
}

extension PersistenceReaderKey where Self == PersistenceKeyDefault<
FileStorageKey<TWSSource>
> {
    static var source: Self {
        PersistenceKeyDefault(.fileStorage(.source), .api)
    }
}
