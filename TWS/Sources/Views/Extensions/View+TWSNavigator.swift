//
//  View+TWSNavigator.swift
//  TWS
//
//  Created by Miha Hozjan on 13. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

extension EnvironmentValues {

    @Entry var navigator = TWSViewNavigator()
}

extension View {

    public func twsBind(
        navigator: TWSViewNavigator
    ) -> some View {
        self
            .environment(\.navigator, navigator)
    }
}
