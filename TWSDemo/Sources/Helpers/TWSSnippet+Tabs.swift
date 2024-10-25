//
//  TWSSnippet+Tabs.swift
//  TheWebSnippet
//
//  Created by Miha Hozjan on 23. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import TWSKit

extension TWSSnippet {

    public var isTab: Bool {
        props?[.tabName, as: \.string] != nil || props?[.tabIcon, as: \.string] != nil
    }

}

extension TWSManager {

    var tabs: [TWSSnippet] {
        self.snippets.filter(\.isTab)
    }
}
