//
//  TWSViewModel.swift
//  TWSDemo
//
//  Created by Miha Hozjan on 30. 05. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI
import TWSModels
import TWSKit

@Observable
class TWSViewModel {

    let manager = TWSFactory.new()
    var snippets: [TWSSnippet]

    init() {
        snippets = manager.snippets
        manager.run()
    }
}
