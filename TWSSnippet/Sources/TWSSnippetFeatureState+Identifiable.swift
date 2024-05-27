//
//  TWSSnippetFeatureState+Identifiable.swift
//  TWSSnippet
//
//  Created by Miha Hozjan on 27. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels

extension TWSSnippetFeature.State: Identifiable {
    
    public var id: TWSSnippet.ID {
        return snippet.id
    }
}
