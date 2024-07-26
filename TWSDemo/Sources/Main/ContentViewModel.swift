//
//  ContentViewModel.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 23. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation

@Observable
class ContentViewModel {

    var tab: Tab = .snippets
    var webViewTitle: String = ""
}

extension ContentViewModel {

    enum Tab: Hashable {
        case snippets, fullscreenSnippets, settings
    }
}
