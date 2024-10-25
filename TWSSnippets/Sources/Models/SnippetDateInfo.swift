//
//  SnippetDateInfo.swift
//  TheWebSnippet
//
//  Created by Luka Kit on 24. 10. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import Foundation
import ComposableArchitecture

public struct SnippetDateInfo: Equatable, Codable, Sendable {
    let serverTime: Date
    let phoneTime: Date
    public var adaptedTime: Date {
        serverTime.addingTimeInterval(getElapsedSecondsSinceLastUpdate())
    }

    init(serverTime: Date) {
        @Dependency(\.date) var date
        self.serverTime = serverTime
        self.phoneTime = date.now
    }

    private func getElapsedSecondsSinceLastUpdate() -> TimeInterval {
        @Dependency(\.date) var date
        return date.now.timeIntervalSince(phoneTime)
    }
}
