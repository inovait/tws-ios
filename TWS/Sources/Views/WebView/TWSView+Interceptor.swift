//
//  TWSView+Interceptor.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 14. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

@MainActor
public protocol TWSViewInterceptorDelegate: AnyObject, Sendable {

    func handleUrl(_ url: URL) -> Bool
}

@MainActor
@Observable
public class TWSViewInterceptor: Sendable {

    weak var delegate: TWSViewInterceptorDelegate?

    nonisolated public init() { }

    public func handleUrl(_ url: URL) -> Bool {
        return delegate?.handleUrl(url) ?? false
    }
}
