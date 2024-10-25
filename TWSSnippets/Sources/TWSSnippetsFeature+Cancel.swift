//
//  TWSSnippetsFeature+Cancel.swift
//  TWSSnippets
//
//  Created by Miha Hozjan on 30. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels

extension TWSSnippetsFeature {

    // It is important to further differentiate cancel events with `TWSConfiguration`
    // This is because TCA uses combine pipelines, which means the same hashable value
    // could potentially leak to all active stores.
    enum CancelID: Hashable {
        case socket(TWSConfiguration),
             reconnect(TWSConfiguration),
             showSnippet(TWSSnippet.ID),
             hideSnippet(TWSSnippet.ID)
    }
}
