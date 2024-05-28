//
//  SharedSnippets.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 28. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSCommon
import TWSModels
import TWSSnippet
import ComposableArchitecture

extension URL {
    static let snippets = URL.documentsDirectory.appending(component: "snippets.json")
}

extension PersistenceReaderKey where Self == 
PersistenceKeyDefault<
FileStorageKey<IdentifiedArrayOf<TWSSnippetFeature.State>>
>
{

    static var snippets: Self {
        PersistenceKeyDefault(.fileStorage(.snippets), [])
    }
}
