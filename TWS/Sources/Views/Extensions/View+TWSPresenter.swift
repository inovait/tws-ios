//
//  View+TWSPresenter.swift
//  TWS
//
//  Created by Miha Hozjan on 11. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

extension EnvironmentValues {

    @Entry var twsPresenter: TWSPresenter = NoopPresenter()
}
