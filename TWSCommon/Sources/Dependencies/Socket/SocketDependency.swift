//
//  SocketDependency.swift
//  TWSCommon
//
//  Created by Miha Hozjan on 12. 06. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
import ComposableArchitecture
import TWSModels

public struct SocketDependency {

    public var get: @Sendable (TWSConfiguration, URL) async -> UUID
    public var connect: @Sendable (UUID) async throws -> AsyncStream<WebSocketEvent>
    public var listen: @Sendable (UUID) async throws -> Void
    public var closeConnection: @Sendable (UUID) async -> Void
    public var abort: @Sendable (TWSConfiguration) async -> Void
}

public enum SocketDependencyKey: DependencyKey {

    public static var liveValue: SocketDependency {
        let storage = ActorIsolatedDictionary<UUID, SocketConnector>([:])
        let configuration = ActorIsolatedDictionary<TWSConfiguration, UUID>([:])

        return .init(
            get: { [storage, configuration] config, url in
                let id = UUID()
                let socket = SocketConnector(url: url)
                await storage.setValue(socket, forKey: id)
                await configuration.setValue(id, forKey: config)
                return id
            },
            connect: { [storage] id in
                guard let socket = await storage.getValue(forKey: id)
                else { preconditionFailure("Sending a `connect` message to an invalid object: \(id)") }
                try await socket.connect()
                return await socket.stream
            },
            listen: { [storage] id in
                guard let socket = await storage.getValue(forKey: id)
                else { preconditionFailure("Sending a `listen` message to an invalid object: \(id)") }
                try await socket.listen()
            },
            closeConnection: { [storage] id in
                guard let socket = await storage.getValue(forKey: id)
                else { return }

                await socket.closeConnection()
                await storage.removeValue(forKey: id)
            },
            abort: { [storage, configuration] config in
                guard
                    let connection = await configuration.getValue(forKey: config),
                    let socket = await storage.getValue(forKey: connection)
                else {
                    assertionFailure("A manager has deinited, but there is no connection left to be nilled?")
                    return
                }

                await socket.closeConnection()
                await configuration.removeValue(forKey: config)
                await storage.removeValue(forKey: connection)
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
