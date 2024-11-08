//
//  TWSUniversalLinksFeature.swift
//  TWSUniversalLinks
//
//  Created by Luka Kit on 27. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import Foundation
import ComposableArchitecture
import TWSCommon
@_spi(Internals) import TWSModels

@Reducer
public struct TWSUniversalLinksFeature: Sendable {

    @ObservableState
    public struct State: Equatable {
        public init() { }
    }

    @CasePathable
    public enum Action {

        @CasePathable
        public enum BusinessAction {
            case onUniversalLink(URL)
            case snippetLoaded(Result<TWSSharedSnippet, Error>)
            case notifyClient(TWSSharedSnippetBundle)
        }

        @CasePathable
        public enum DelegateAction {
            case snippetLoaded(TWSSharedSnippetBundle)
        }

        case business(BusinessAction)
        case delegate(DelegateAction)
    }

    @Dependency(\.api) var api
    @Dependency(\.configuration) var configuration

    public init() { }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .business(.onUniversalLink(url)):
            guard !url.isTWSAuthenticationRequest()
            else { return .none }
            logger.info("Received a universal link: \(url)")

            do {
                switch try TWSUniversalLinkRouter.route(for: url) {
                case let .snippet(id):
                    return .run { [api, configuration] send in
                        do {
                            let snippet = try await api.getSnippetBySharedId(configuration(), id)
                            await send(.business(.snippetLoaded(.success(snippet))))
                        } catch {
                            await send(.business(.snippetLoaded(.failure(error))))
                        }
                    }
                }
            } catch {
                dump(error)
                logger.err("Failed to process an universal link: \(url), error: \(error.localizedDescription)")
                return .none
            }

        case let .business(.snippetLoaded(.success(snippet))):
            logger.info("Universal link: snippet loaded successfully")
            return .run { [api] send in
                let resources = await preloadResources(for: snippet, using: api)
                let aggregated = TWSSharedSnippetBundle(
                    sharedSnippet: snippet,
                    resources: resources
                )

                await send(.business(.notifyClient(aggregated)))
            }

        case let .business(.snippetLoaded(.failure(error))):
            logger.err("Universal link: load failed: \(error.localizedDescription)")
            return .none

        case let .business(.notifyClient(aggregatedSnippet)):
            return .send(.delegate(.snippetLoaded(aggregatedSnippet)))

        case .delegate:
            return .none
        }
    }
}
