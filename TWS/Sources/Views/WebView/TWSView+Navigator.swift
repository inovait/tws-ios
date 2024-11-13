//
//  TWSView+Navigator.swift
//  TWS
//
//  Created by Miha Hozjan on 13. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

@MainActor
public protocol TWSViewNavigatorDelegate: AnyObject, Sendable {

    func navigateBack()
    func navigateForward()
    func reload()
}

@MainActor
@Observable
public class TWSViewNavigator: Sendable {

    public internal(set) var canGoBack = false
    public internal(set) var canGoForward = false
    weak var delegate: TWSViewNavigatorDelegate?

    nonisolated public init() { }

    public func goBack() {
        delegate?.navigateBack()
    }

    public func goForward() {
        delegate?.navigateForward()
    }

    public func reload() {
        delegate?.reload()
    }
}
