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
        public internal(set) var loadedSnippet: TWSSnippet?

        public init() { }
    }

    public enum Action {

        @CasePathable
        public enum BusinessAction {
            case loadSnippet(URL)
            case snippetLoaded(Result<TWSSnippet, Error>)
            case clearLoadedSnippet
        }

        case business(BusinessAction)
    }

    @Dependency(\.api) var api

    public init() { }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .business(.loadSnippet(let readUrl)):
            logger.info("Received QR code URL to parse: \(readUrl)")
            let urlParser = TWSUniversalLinksParser()
            let snippetId = urlParser.getSnippetIdFromURL(readUrl)

            return .run { [api] send in
                do {
                    let snippet = try await api.getSnippetById(snippetId)
                    await send(.business(.snippetLoaded(.success(snippet))))
                } catch {
                    await send(.business(.snippetLoaded(.failure(error))))
                }
            }

        case let .business(.snippetLoaded(.success(snippet))):
            logger.info("QR snippet loaded successfully")
            state.loadedSnippet = snippet
            return .none

        case let .business(.snippetLoaded(.failure(error))):
            logger.err("QR snippet load failed: \(error.localizedDescription)")
            state.loadedSnippet = nil
            return .none

        case .business(.clearLoadedSnippet):
            state.loadedSnippet = nil
            return .none
        }

    }
}
