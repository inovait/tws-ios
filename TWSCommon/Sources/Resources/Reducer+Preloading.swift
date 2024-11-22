//
//  Reducer+Preloading.swift
//  TWSModels
//
//  Created by Miha Hozjan on 27. 9. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import Foundation
@_spi(Internals) import TWSModels
import ComposableArchitecture

public extension Reducer {

    // MARK: - Loading resources

    func preloadResources(
        for snippet: TWSSnippet,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let resources = snippet.allResources(headers: &headers)

        return await _preloadResources(
            resources: resources,
            headers: headers,
            using: api
        )
    }

    func preloadResources(
        for project: TWSProject,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let resources = project.allResources(headers: &headers)

        return await _preloadResources(
            resources: resources,
            headers: headers,
            using: api
        )
    }

    func preloadResources(
        for sharedSnippet: TWSSharedSnippet,
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        var headers = [TWSSnippet.Attachment: [String: String]]()
        let resources = sharedSnippet.allResources(headers: &headers)

        return await _preloadResources(
            resources: resources,
            headers: headers,
            using: api
        )
    }

    // MARK: - Helpers

    private func _preloadResources(
        resources: [TWSSnippet.Attachment],
        headers: [TWSSnippet.Attachment: [String: String]],
        using api: APIDependency
    ) async -> [TWSSnippet.Attachment: String] {
        return await withTaskGroup(
            of: (TWSSnippet.Attachment, String)?.self,
            returning: [TWSSnippet.Attachment: String].self
        ) { [api] group in
            // Use a set to download each resource only once, even if it is used in multiple snippets
            for resource in Set(resources) {
                group.addTask { [resource] in
                    do {
                        let payload = try await api.getResource(resource, headers[resource] ?? [:])
                        if !payload.isEmpty { return (resource, payload) }
                        return nil
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
