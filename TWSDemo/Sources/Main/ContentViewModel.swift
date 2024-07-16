//
//  ContentViewModel.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSKit

@Observable
class ContentViewModel {

    var tab: Tab = .snippets
    var fullscreenSnippet: TWSSnippet?
    var displayFullscreenSnippet: Bool = false
    var webViewTitle: String = ""
}

extension ContentViewModel {

    enum Tab: Hashable {
        case snippets, fullscreenSnippets, settings
    }
}
