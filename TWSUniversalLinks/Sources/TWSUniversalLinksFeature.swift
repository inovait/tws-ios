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
import TWSModels

@Reducer
public struct TWSUniversalLinksFeature {

    @ObservableState
    public struct State: Equatable {
        public init() { }
    }

    public enum Action {

        @CasePathable
        public enum BusinessAction {
            case onUniversalLink(URL)
            case snippetLoaded(Result<TWSSnippet, Error>)
        }

        @CasePathable
        public enum DelegateAction {
            case snippetLoaded(TWSSnippet)
        }

        case business(BusinessAction)
        case delegate(DelegateAction)
    }

    @Dependency(\.api) var api

    public init() { }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .business(.onUniversalLink(url)):
            guard !url.isTWSAuthenticationRequest()
            else { return .none }
            logger.info("Received a universal link: \(url)")

            do {
                switch try universalLinksRouter.match(url: url) {
                case let .snippet(id):
                    return .run { [api] send in
                        do {
                            let snippet = try await api.getSnippetById(id)
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
            logger.info("QR snippet loaded successfully")
            return .send(.delegate(.snippetLoaded(snippet)))

        case let .business(.snippetLoaded(.failure(error))):
            logger.err("QR snippet load failed: \(error.localizedDescription)")
            return .none

        case .delegate:
            return .none
        }
    }
}
