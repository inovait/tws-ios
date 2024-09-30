//
//  Reducer+Preloading.swift
//  TWSModels
//
//  Created by Miha Hozjan on 27. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
@_spi(InternalLibraries) import TWSModels
import ComposableArchitecture

public extension Reducer {

    func preloadResources(
        for project: TWSProject,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        let attachments = project.snippets
            .compactMap(\.dynamicResources)
            .flatMap { $0 }

        guard !attachments.isEmpty else { return [:] }
        return await _preloadResources(resources: attachments, using: api)
    }

    func preloadResources(
        for sharedSnippet: TWSSharedSnippet,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        let attachments = sharedSnippet.snippet.dynamicResources ?? []
        guard !attachments.isEmpty else { return [:] }
        return await _preloadResources(resources: attachments, using: api)
    }

    private func _preloadResources(
        resources: [TWSSnippet.Attachment],
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        return await withTaskGroup(
            of: (TWSSnippet.Attachment, String)?.self,
            returning: [TWSSnippet.Attachment: String].self
        ) { [api] group in
            for resource in resources {
                group.addTask { [resource] in
                    do {
                        let payload = try await api.getResource(resource)
                        return (resource, payload)
                    } catch {
                        return nil
                    }
                }
            }

            var results: [TWSSnippet.Attachment: String] = [:]
            for await result in group {
                guard let result else { continue }
                results[result.0] = result.1
            }

            return results
        }
    }
}
