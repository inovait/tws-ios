//
//  TWSSnippet+Tabs.swift
//  TheWebSnippet
//
//  Created by Miha Hozjan on 23. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import TWSModels

extension TWSSnippet {

    public var isTab: Bool {
        props?[.tabName, as: \.string] != nil
    }
}
