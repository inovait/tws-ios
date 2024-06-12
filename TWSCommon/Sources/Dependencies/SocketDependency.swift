//
//  SocketDependency.swift
//  TWSCommon
//
//  Created by Miha Hozjan on 12. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import TWSModels
import ComposableArchitecture

public struct SocketDependency {

    public var connect: @Sendable (URL) async -> AsyncStream<WebSocketEvent>
}

public enum SocketDependencyKey: DependencyKey {

    public static var liveValue: SocketDependency {
        .init(
            connect: { _ in
                fatalError()
            }
        )
    }
}

public extension DependencyValues {

    var socket: SocketDependency {
        get { self[SocketDependencyKey.self] }
        set { self[SocketDependencyKey.self] = newValue }
    }
}

// TODO: move

public enum WebSocketEvent {
    case didConnect, didDisconnect, receivedMessage(Data)
}

//public struct WebSocketMock {
//
//    var sen
//}
