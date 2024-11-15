//
//  TWSView+Interceptor.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 14. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

@MainActor
public protocol TWSViewInterceptor: AnyObject, Sendable {

    func handleUrl(_ url: URL) -> Bool
}
